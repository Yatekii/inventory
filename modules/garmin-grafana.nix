{ lib, pkgs, config, inputs, ... }:
let
  garmin-grafana-path = "/var/lib/garmin-grafana";
  garmin-grafana-path-relative = "garmin-grafana";
  garmin-grafana-user = "garmin-grafana";
  grafana-group = "caddy";
  influxdb-password =
    config.clan.core.vars.generators.garmin-grafana.files.influx-password.path;
  garmin-env =
    config.clan.core.vars.generators.garmin-grafana.files.garmin-env.path;
  influxdb-port = 8088;
  influxdb-host = "localhost";

  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = inputs.garmin-grafana;
  };

  overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

  # fitparse does not have a wheel. Only an sdist.
  pyprojectOverrides = final: prev: {
    fitparse = prev.fitparse.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs
        ++ final.resolveBuildSystem { setuptools = [ ]; };
    });
  };

  python = pkgs.python313;

  pythonSet = (pkgs.callPackage inputs.pyproject-nix.build.packages {
    inherit python;
  }).overrideScope (lib.composeManyExtensions [
    inputs.pyproject-build-systems.overlays.default
    overlay
    pyprojectOverrides
  ]);

  venv = pythonSet.mkVirtualEnv "garmin-grafana-env" workspace.deps.default;

  garmin-grafana-derivation =
    (pkgs.callPackages inputs.pyproject-nix.build.util { }).mkApplication {
      venv = venv;
      package = pythonSet.garmin-grafana;
    };
in {
  imports = [ ./grafana.nix ];

  clan.core.vars.generators.garmin-grafana = {
    prompts.garmin-email-input = {
      description = "The Garmin user email";
      type = "line";
      persist = false;
    };
    prompts.garmin-password-input = {
      description = "The Garmin password";
      type = "hidden";
      persist = false;
    };
    script = ''
      ifdpassword=$(pwgen 64 1);
      echo "$ifdpassword" > "$out/influx-password"

      email=$(cat "$prompts/garmin-email-input");
      password=$(base64 "$prompts/garmin-password-input");
      printf "GARMINCONNECT_EMAIL=%s\n" "$email" > "$out/garmin-env";
      printf "GARMINCONNECT_BASE64_PASSWORD=%s\n" "$password" >> "$out/garmin-env";
      printf "INFLUXDB_PASSWORD=%s\n" "$ifdpassword" >> "$out/garmin-env";
    '';
    runtimeInputs = [ pkgs.pwgen ];
    files.influx-password = {
      owner = garmin-grafana-user;
      group = grafana-group;
      mode = "0440";
    };
    files.garmin-env = { owner = garmin-grafana-user; };
  };

  systemd.services.garmin-grafana = {
    description = "garmin-grafana";
    wantedBy = [ "multi-user.target" ];
    environment = {
      INFLUXDB_HOST = "localhost";
      INFLUXDB_PORT = "8086"; # it's hardcoded in the influxdb NixOS module
      INFLUXDB_USERNAME = "garmin-grafana";
      INFLUXDB_DATABASE = "garmin-stats";
      GARMINCONNECT_IS_CN = "False";
      USER_TIMEZONE = "Europe/Zurich";
      KEEP_FIT_FILES = "True";
      ALWAYS_PROCESS_FIT_FILES = "True";
      MANUAL_START_DATE = "2015-06-01";
      MANUAL_END_DATE = "2025-12-31";
    };
    serviceConfig = {
      ExecStart = lib.getExe garmin-grafana-derivation;
      Group = garmin-grafana-user;
      User = garmin-grafana-user;
      StateDirectory = garmin-grafana-path-relative;
      WorkDirectory = garmin-grafana-path-relative;
      EnvironmentFile = garmin-env;
    };
  };

  users.users.garmin-grafana = {
    isSystemUser = true;
    group = garmin-grafana-user;
    extraGroups = [ garmin-grafana-user ];
    home = garmin-grafana-path;
  };
  users.groups.garmin-grafana = { };

  services.grafana.provision.dashboards.settings.providers = [{
    name = "Garmin Grafana Dashboards";
    options.path = "${garmin-grafana-derivation}/Grafana_Dashboard/";
  }];

  services.influxdb.enable = true;
  services.grafana.provision.datasources.settings.datasources = [{
    name = "Garmin Influxdb";
    uid = "garmin-influxdb";
    type = "influxdb";
    access = "proxy";
    database = "GarminStats";
    isDefault = true;
    editable = false;
    secureJsonData.password = "$__file{${influxdb-password}}";
    url = "http://${influxdb-host}:${toString influxdb-port}";
    jsonData.httpMode = "GET";
  }];
}

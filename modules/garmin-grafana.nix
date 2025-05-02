{ lib, pkgs, config, sources, ... }:
let
  garmin-grafana-path = "/var/lib/garmin-grafana";
  garmin-grafana-user = "garmin-grafana";
  grafana-group = config.systemd.services.grafana.serviceConfig.Group;
  grafana-user = config.systemd.services.grafana.serviceConfig.User;
  influxdb-password =
    config.clan.core.vars.generators.garmin-grafana.files.influx-password.value;
  influxdb-port = 8088;
  influxdb-host = "localhost";

  workspace = sources.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = sources.garmin-grafana;
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

  pythonSet = (pkgs.callPackage sources.pyproject-nix.build.packages {
    inherit python;
  }).overrideScope (lib.composeManyExtensions [
    sources.pyproject-build-systems.overlays.default
    overlay
    pyprojectOverrides
  ]);

  venv = pythonSet.mkVirtualEnv "garmin-grafana-env" workspace.deps.default;

  garmin-grafana =
    (pkgs.callPackages sources.pyproject-nix.build.util { }).mkApplication {
      venv = venv;
      package = pythonSet.garmin-grafana;
    };
in {
  imports = [ ./grafana.nix ];

  clan.core.vars.generators.garmin-grafana = {
    script = ''
      pwgen 64 1 > "$out/influx-password"
    '';
    runtimeInputs = [ pkgs.pwgen ];
    files.influx-password = {
      secret = false;
      owner = garmin-grafana-user;
    };
  };

  systemd.services.garmin-grafana = {
    description = "garmin-grafana";
    wantedBy = [ "multi-user.target" ];
    environment = {
      INFLUXDB_HOST = "localhost";
      INFLUXDB_PORT = "8086"; # it's hardcoded in the influxdb NixOS module
      INFLUXDB_USERNAME = "garmin-grafana";
      INFLUXDB_PASSWORD = influxdb-password;
      INFLUXDB_DATABASE = "garmin-stats";
      GARMINCONNECT_IS_CN = "False";
      USER_TIMEZONE = "Europe/Zurich";
      KEEP_FIT_FILES = "True";
      ALWAYS_PROCESS_FIT_FILES = "True";
      # MANUAL_START_DATE = "2024-06-01";
      # MANUAL_END_DATE = "2025-12-31";
    };
    serviceConfig = {
      ExecStart = lib.getExe garmin-grafana;
      Group = garmin-grafana-user;
      User = garmin-grafana-user;
      WorkingDirectory = garmin-grafana-path;
    };
  };

  users.users.garmin-grafana = {
    isSystemUser = true;
    group = garmin-grafana-user;
    extraGroups = [ garmin-grafana-user ];
    home = garmin-grafana-path;
  };
  users.groups.garmin-grafana = { };

  environment.etc."grafana-dashboards/garmin.json" = {
    source =
      "${sources.garmin-grafana}/Grafana_Dashboard/Garmin-Grafana-Dashboard.json";
    group = grafana-group;
    user = grafana-user;
  };

  services.influxdb.enable = true;
  services.grafana.provision.datasources.settings.datasources = [{
    name = "Garmin Influxdb";
    uid = "garmin-influxdb";
    type = "influxdb";
    access = "proxy";
    database = "GarminStats";
    isDefault = true;
    editable = false;
    secureJsonData.password = influxdb-password;
    url = "http://${influxdb-host}:${toString influxdb-port}";
    jsonData.httpMode = "GET";
  }];
}

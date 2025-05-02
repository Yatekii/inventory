{ pkgs, config, ... }:
let
  grafana-user = "grafana";
  grafana-domain = "grafana.aiur.huesser.dev";
  grafana-socket = "/run/grafana/grafana.sock";
in {
  clan.core.vars.generators.grafana = {
    script = ''
      pwgen 64 1 > "$out/admin-password"
    '';
    runtimeInputs = [ pkgs.pwgen ];
    files.admin-password = {
      secret = true;
      owner = grafana-user;
    };
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        domain = grafana-domain;
        socket = grafana-socket;
        protocol = "socket";
        root_url = "https://${grafana-domain}/";
      };
      security = {
        admin_user = "admin";
        admin_password =
          "$__file{${config.clan.core.vars.generators.grafana.files.admin-password.path}}";
      };
    };

    provision = {
      enable = true;
      dashboards.settings.providers = [{
        name = "Grafana Dashboards";
        options.path = "/etc/grafana-dashboards";
      }];
    };
  };
  systemd.services.grafana.serviceConfig.Group = "caddy";

  services.caddy.virtualHosts."${grafana-domain}".extraConfig = ''
    reverse_proxy /* unix/${grafana-socket}
  '';
}

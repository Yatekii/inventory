{ config, pkgs, names, ... }:
let
  vaultwarden-domain = "nvaultwarden.huesser.dev";
  vaultwarden-signups-allowed = false;
  vaultwarden-admin-token =
    config.clan.core.vars.generators.admin-token.files.admin-token.path;
  vaultwarden-log-file = "${vaultwarden-path}vaultwarden.log";
  vaultwarden-websocket-enabled = true;
  vaultwarden-host = "127.0.0.1";
  vaultwarden-port = 8222;
  vaultwarden-websocket-port = 3012;

  vaultwarden-path = "/var/lib/vaultwarden";
  vaultwarden-backup-path-relative = "vaultwarden-backup";
  vaultwarden-backup-path = "/var/lib/${vaultwarden-backup-path-relative}";
  vaultwarden-user = "vaultwarden";
  vaultwarden-backup = (pkgs.writeShellApplication {
    name = "vaultwarden-backup";
    runtimeInputs = [ pkgs.sqlite3 ];
    text = ''
      set -eu
      systemctl stop vaultwarden
      cp ${vaultwarden-path}/attachments ${vaultwarden-backup-path}/attachments
      sqlite3 ${vaultwarden-path}/db.sqlite3 ".backup '${vaultwarden-backup-path}/db.sqlite3'"
      systemctl start vaultwarden
    '';
  });
  vaultwarden-restore = (pkgs.writeShellApplication {
    name = "vaultwarden-restore";
    runtimeInputs = [ ];
    text = ''
      set -eu
      systemctl stop vaultwarden
      cp ${vaultwarden-backup-path}/attachments ${vaultwarden-path}/attachments
      cp ${vaultwarden-backup-path}/db.sqlite3 ${vaultwarden-path}/db.sqlite3
      rm ${vaultwarden-path}/db.sqlite3-wal
      sqlite3 ${vaultwarden-path}/db.sqlite3 ".backup '${vaultwarden-backup-path}/db.sqlite3'"
      systemctl start vaultwarden
    '';
  });
in {
  # imports = [ ../modules/caddy.nix ];

  # environment.systemPackages = [ vaultwarden-backup vaultwarden-restore ];

  # services.vaultwarden = {
  #   enable = true;
  #   dbBackend = "sqlite";
  #   domain = "https://${vaultwarden-domain}";
  #   config = {
  #     SIGNUPS_ALLOWED = vaultwarden-signups-allowed;
  #     ADMIN_TOKEN = vaultwarden-admin-token;
  #     LOG_FILE = vaultwarden-log-file;
  #     WEBSOCKET_ENABLED = vaultwarden-websocket-enabled;
  #     ROCKET_ADDRESS = vaultwarden-host;
  #     ROCKET_PORT = vaultwarden-port;
  #   };
  # };

  # clan.core.vars.generators.admin-token = {
  #   prompts.admin-token.description = "the PSK for administrating vaultwarden";
  #   prompts.admin-token.type = "hidden";
  #   prompts.admin-token.persist = true;
  #   files.admin-token = {
  #     secret = true;
  #     owner = vaultwarden-user;
  #   };
  # };

  # services.caddy.virtualHosts."${vaultwarden-domain}".extraConfig = ''
  #   reverse_proxy /* ${vaultwarden-host}:${toString vaultwarden-port}
  # '' + (if vaultwarden-websocket-enabled then ''
  #   reverse_proxy /notifications/hub ${vaultwarden-host}:${
  #     toString vaultwarden-websocket-port
  #   }
  # '' else
  #   "");

  # clan.core.state.vaultwarden = {
  #   folders = [ vaultwarden-backup-path ];
  #   preBackupScript = "${vaultwarden-backup}/bin/vaultwarden-backup";
  #   postRestoreScript = "${vaultwarden-backup}/bin/vaultwarden-restore";
  # };

  # programs.ssh.knownHosts = {
  #   storagebox-ed25519.hostNames =
  #     [ "[${names.hetzner-offsite-backup-host}]:23" ];
  #   storagebox-ed25519.publicKey =
  #     "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
  # };

  # networking.firewall = {
  #   enable = true;
  #   allowedTCPPorts = [ 80 443 ];
  # };
}

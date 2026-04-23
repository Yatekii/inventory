{
  config,
  pkgs,
  names,
  ...
}:
let
  vaultwarden-domain = "vaultwarden.huesser.dev";
  vaultwarden-signups-allowed = false;
  # Env-format file containing ADMIN_TOKEN=<random>. systemd loads it
  # via EnvironmentFile= at service start, so the secret never enters
  # the store. services.vaultwarden.config only accepts plain scalars,
  # not clan's `_secret` shape — that's what makes environmentFile the
  # right injection point.
  vaultwarden-env-file =
    config.clan.core.vars.generators.vaultwarden.files.env.path;
  vaultwarden-websocket-enabled = true;
  vaultwarden-host = "127.0.0.1";
  vaultwarden-port = 8222;
  vaultwarden-websocket-port = 3012;

  vaultwarden-path = "/var/lib/vaultwarden";
  vaultwarden-backup-path-relative = "vaultwarden-backup";
  vaultwarden-backup-path = "/var/lib/${vaultwarden-backup-path-relative}";
  vaultwarden-user = "vaultwarden";

  # Online SQLite backup + attachments copy, writes to a sibling directory
  # that the clan restic service picks up via clan.core.state below. sqlite3
  # `.backup` is the canonical hot-snapshot mechanism; safe to run while the
  # server is serving requests.
  vaultwarden-backup = pkgs.writeShellApplication {
    name = "vaultwarden-backup";
    runtimeInputs = [ pkgs.sqlite ];
    text = ''
      set -eu
      install -d -o ${vaultwarden-user} -g ${vaultwarden-user} -m 0700 ${vaultwarden-backup-path}
      sqlite3 ${vaultwarden-path}/db.sqlite3 ".backup '${vaultwarden-backup-path}/db.sqlite3'"
      # Attachments + Sends + JWT signing keys + admin-panel config.
      for p in attachments sends rsa_key.der rsa_key.pem rsa_key.pub.der rsa_key.pub.pem config.json; do
        if [ -e "${vaultwarden-path}/$p" ]; then
          cp -a "${vaultwarden-path}/$p" "${vaultwarden-backup-path}/"
        fi
      done
    '';
  };

  vaultwarden-restore = pkgs.writeShellApplication {
    name = "vaultwarden-restore";
    runtimeInputs = [ pkgs.sqlite ];
    text = ''
      set -eu
      systemctl stop vaultwarden
      install -d -o ${vaultwarden-user} -g ${vaultwarden-user} -m 0700 ${vaultwarden-path}
      cp -a ${vaultwarden-backup-path}/db.sqlite3 ${vaultwarden-path}/db.sqlite3
      rm -f ${vaultwarden-path}/db.sqlite3-wal ${vaultwarden-path}/db.sqlite3-shm
      for p in attachments sends rsa_key.der rsa_key.pem rsa_key.pub.der rsa_key.pub.pem config.json; do
        if [ -e "${vaultwarden-backup-path}/$p" ]; then
          cp -a "${vaultwarden-backup-path}/$p" "${vaultwarden-path}/"
        fi
      done
      chown -R ${vaultwarden-user}:${vaultwarden-user} ${vaultwarden-path}
      systemctl start vaultwarden
    '';
  };
in
{
  environment.systemPackages = [
    vaultwarden-backup
    vaultwarden-restore
  ];

  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    environmentFile = vaultwarden-env-file;
    config = {
      DOMAIN = "https://${vaultwarden-domain}";
      SIGNUPS_ALLOWED = vaultwarden-signups-allowed;
      WEBSOCKET_ENABLED = vaultwarden-websocket-enabled;
      ROCKET_ADDRESS = vaultwarden-host;
      ROCKET_PORT = vaultwarden-port;
      WEBSOCKET_ADDRESS = vaultwarden-host;
      WEBSOCKET_PORT = vaultwarden-websocket-port;
      # ADMIN_TOKEN arrives via environmentFile above (systemd EnvironmentFile).
    };
  };

  clan.core.vars.generators.vaultwarden = {
    # Random 64-char admin token, wrapped in KEY=VAL for systemd
    # EnvironmentFile=. Retrieve the raw token once for admin-panel access:
    #   clan vars get saru vaultwarden/env
    # (output shows the full `ADMIN_TOKEN=<token>` line — strip the prefix)
    # Future vaultwarden-related vars (SMTP creds, etc.) go in the same
    # file, one KEY=VAL line each.
    script = ''
      echo "ADMIN_TOKEN=$(${pkgs.pwgen}/bin/pwgen -s 64 1)" > $out/env
    '';
    files.env = {
      secret = true;
      owner = vaultwarden-user;
      mode = "0400";
    };
  };

  services.caddy.virtualHosts."${vaultwarden-domain}".extraConfig = ''
    reverse_proxy /* ${vaultwarden-host}:${toString vaultwarden-port}
  ''
  + (
    if vaultwarden-websocket-enabled then
      ''
        reverse_proxy /notifications/hub ${vaultwarden-host}:${toString vaultwarden-websocket-port}
      ''
    else
      ""
  );

  # clan restic picks these folders up; pre-hook writes a consistent SQLite
  # snapshot + copies of attachments/keys; post-restore puts them back.
  clan.core.state.vaultwarden = {
    folders = [ vaultwarden-backup-path ];
    preBackupScript = "${vaultwarden-backup}/bin/vaultwarden-backup";
    postRestoreScript = "${vaultwarden-restore}/bin/vaultwarden-restore";
  };

  programs.ssh.knownHosts = {
    storagebox-ed25519.hostNames = [ "[${names.hetzner-offsite-backup-host}]:23" ];
    storagebox-ed25519.publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
  };
}

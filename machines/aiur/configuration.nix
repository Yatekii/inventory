{ config, pkgs, conduwuit, names, ... }:
let
  conduwuit-package = conduwuit.packages.x86_64-linux.all-features;
  conduwuit-socket = "/run/conduwuit/conduwuit.sock";
  conduwuit-path = "/var/lib/conduwuit";
  conduwuit-backup-path-relative = "conduwuit-backup";
  conduwuit-backup-path = "/var/lib/${conduwuit-backup-path-relative}";
  conduwuit-restore-path = "/var/lib/conduwuit-restore";
  conduwuit-user = "conduwuit";
  conduwuit-config = (pkgs.formats.toml { }).generate "conduwuit.toml"
    (config.services.conduwuit).settings;
  conduwuit-backup = (pkgs.writeShellApplication {
    name = "conduwuit-backup";
    runtimeInputs = [ ];
    text = ''
      set -eu
      PID=$(systemctl show --property MainPID --value conduwuit)
      kill -s SIGUSR2 "$PID"
    '';
  });
  conduwuit-restore = (pkgs.writeShellApplication {
    name = "conduwuit-restore";
    runtimeInputs = [ ];
    text = ''
      set -eu
      systemctl stop conduwuit
      # create a new directory for merging together the data
      mkdir ${conduwuit-restore-path}
      cd ${conduwuit-restore-path}
      cp ${conduwuit-backup-path}/shared_checksum/*.sst .
      for file in *.sst; do mv "$file" "$(echo "$file" | sed 's/_s.*/.sst/')"; done
      mv ${conduwuit-restore-path} ${conduwuit-path}
      systemctl start conduwuit
    '';
  });
  # conduwuit-admin = (pkgs.writeShellApplication {
  #   name = "conduwuit-admin";
  #   runtimeInputs = [ conduwuit.packages.x86_64-linux.all-features ];
  #   text = ''
  #     systemctl stop conduwuit
  #     export CONDUWUIT_CONFIG=${conduwuit-config};
  #     ${conduwuit.packages.x86_64-linux.all-features}/bin/conduwuit --execute "$*" --execute "server shutdown"
  #     systemctl start conduwuit
  #   '';
  # });

in {
  imports = [
    # contains your disk format and partitioning configuration.
    ../../modules/disko.nix
    # this file is shared among all machines
    ../../modules/shared.nix
    ../../modules/caddy.nix
    ../../modules/grafana.nix
    ../../modules/garmin-grafana.nix
  ];

  # Set this for clan commands use ssh i.e. `clan machines update`
  # If you change the hostname, you need to update this line to root@<new-hostname>
  # This only works however if you have avahi running on your admin machine else use IP
  clan.core.networking.targetHost = "root@142.132.172.209";

  # You can get your disk id by running the following command on the installer:
  # Replace <IP> with the IP of the installer printed on the screen or by running the `ip addr` command.
  # ssh root@<IP> lsblk --output NAME,ID-LINK,FSTYPE,SIZE,MOUNTPOINT
  disko.devices.disk.main.device =
    "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_59606587";

  # IMPORTANT! Add your SSH key here
  # e.g. > cat ~/.ssh/id_ed25519.pub
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/zWoCMabsPjao7AZKfA1jvokjbOBxyGHHKOwTA9krw auraya"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQC2K0wDAi6HBOn0kXGBGRw4zjdGivMCSF84P/w7y2f arcturo"
  ];

  # Zerotier needs one controller to accept new nodes. Once accepted
  # the controller can be offline and routing still works.
  clan.core.networking.zerotier.controller.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 8448 ];
  };

  # environment.systemPackages = [ conduwuit-backup conduwuit-admin ];

  # services.conduwuit = {
  #   enable = true;
  #   package = conduwuit-package;
  #   group = "caddy";
  #   settings.global = {
  #     server_name = "aiur.huesser.dev";
  #     unix_socket_path = conduwuit-socket;
  #     well_known = {
  #       client = "https://matrix.aiur.huesser.dev";
  #       server = "matrix.aiur.huesser.dev:443";
  #       support_email = "noah@huesser.dev";
  #     };
  #     allow_registration = true;
  #     registration_token_file =
  #       config.clan.core.vars.generators.registration-token.files.registration-token.path;
  #     admin_signal_execute = [ "server backup-database" ];
  #     database_backup_path = conduwuit-backup-path;
  #   };
  # };
  systemd.services.conduwuit.serviceConfig.StateDirectory =
    [ conduwuit-backup-path-relative ];

  clan.core.vars.generators.registration-token = {
    prompts.registration-token.description =
      "the PSK for regstering a new matrix account";
    prompts.registration-token.type = "hidden";
    prompts.registration-token.persist = true;
    files.registration-token = {
      secret = true;
      owner = conduwuit-user;
    };
  };

  services.caddy.virtualHosts."aiur.huesser.dev".extraConfig = ''
    reverse_proxy /.well-known/matrix/* unix/${conduwuit-socket}
  '';

  services.caddy.virtualHosts."matrix.aiur.huesser.dev".extraConfig = ''
    reverse_proxy /_matrix/* unix/${conduwuit-socket}
    reverse_proxy /_conduwuit/* unix/${conduwuit-socket}
  '';

  services.caddy.virtualHosts."matrix.aiur.huesser.dev:8448".extraConfig = ''
    reverse_proxy /_matrix/* unix/${conduwuit-socket}
    reverse_proxy /_conduwuit/* unix/${conduwuit-socket}
  '';

  systemd.services."conduwuit-backup" = {
    serviceConfig = {
      Type = "oneshot";
      User = conduwuit-user;
      ExecStart = "${conduwuit-backup}/bin/conduwuit-backup";
    };
    wantedBy = [ "timers.target" ];
    startAt = "04:00";
  };

  clan.core.state.conduwuit = {
    folders = [ conduwuit-backup-path ];
    preBackupScript = "${conduwuit-backup}/bin/conduwuit-backup";
    postRestoreScript = "${conduwuit-backup}/bin/conduwuit-restore";
  };

  programs.ssh.knownHosts = {
    storagebox-ed25519.hostNames =
      [ "[${names.hetzner-offsite-backup-host}]:23" ];
    storagebox-ed25519.publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
  };
}

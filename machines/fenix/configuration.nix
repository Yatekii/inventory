{ names, ... }:
let
  name = "fenix";
  machine = (builtins.fromJSON (builtins.readFile ./../machines.json)).${name};
  ip = machine.ipv4;
  disk-id = machine.disk_id;
in {
  imports = [
    ../../modules/disko.nix
    ../../modules/shared.nix
    # ../../modules/vaultwarden.nix
  ];

  # Set this for clan commands use ssh i.e. `clan machines update`
  # If you change the hostname, you need to update this line to root@<new-hostname>
  # This only works however if you have avahi running on your admin machine else use IP
  clan.core.networking.targetHost = "root@${ip}";

  # You can get your disk id by running the following command on the installer:
  # Replace <IP> with the IP of the installer printed on the screen or by running the `ip addr` command.
  # ssh root@<IP> lsblk --output NAME,ID-LINK,FSTYPE,SIZE,MOUNTPOINT
  disko.devices.disk.main.device = "/dev/disk/by-id/${disk-id}";

  # IMPORTANT! Add your SSH key here
  # e.g. > cat ~/.ssh/id_ed25519.pub
  users.users.root.openssh.authorizedKeys.keys = [''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/zWoCMabsPjao7AZKfA1jvokjbOBxyGHHKOwTA9krw auraya
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQC2K0wDAi6HBOn0kXGBGRw4zjdGivMCSF84P/w7y2f arcturo
  ''];

  # Zerotier needs one controller to accept new nodes. Once accepted
  # the controller can be offline and routing still works.
  clan.core.networking.zerotier.controller.enable = false;

  programs.ssh.knownHosts = {
    storagebox-ed25519.hostNames =
      [ "[${names.hetzner-offsite-backup-host}]:23" ];
    storagebox-ed25519.publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
  };
}

{ ... }:
{
  imports = [
    ./disko.nix
    ../../modules/clan/shared.nix
    ../../modules/clan/nix.nix
    ../../modules/clan/ssh-keys.nix
    ../../modules/clan/helix.nix
    ../../modules/clan/home-manager.nix
    ../../modules/clan/samba.nix
    ../../modules/clan/caddy.nix
    ../../modules/clan/vaultwarden.nix
    ../../modules/clan/jellyfin.nix
    # msmtp pending — waiting to decide mail path (stalwart-on-fenix vs
    # external provider). Module exists at ../../modules/clan/msmtp.nix.
    # ../../modules/clan/msmtp.nix
  ];

  # aiur is the zerotier controller; saru is not.
  clan.core.networking.zerotier.controller.enable = false;

  # System host-id (`/etc/hostid`). Required by ZFS to tag pool ownership —
  # mismatches between pool metadata and this value force `zpool import -f`.
  # Any stable 8-hex value; must not change once the pool has been imported
  # by this host. Lives under `networking.*` for historical reasons; ZFS is
  # the primary consumer today.
  networking.hostId = "5a727504";

  # Until `clan machines init-hardware-config saru` generates facter.json
  # with full hardware detection, set the arch explicitly so the config
  # evaluates. facter.json will set the same value; coexists fine.
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.supportedFilesystems = [ "zfs" ];

  # Import the existing `saru` pool (2x4TB Seagate mirror + 2x14TB WD mirror
  # on sda-sdd). Datasets carry their own mountpoint properties and mount
  # automatically. Phase 0 exports the pool from Ubuntu before
  # `clan machines install`, so first NixOS boot imports cleanly without `-f`.
  boot.zfs.extraPools = [ "saru" ];

  time.timeZone = "Europe/Zurich";
}

{ config, ... }:
{
  # clanModules have been migrated to clanServices in flake.nix inventory.instances:
  # - sshd
  # - users (replaces root-password and user-password)
  # - trusted-nix-caches

  # Enable experimental Nix features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "pipe-operators"
  ];

  # Locale service discovery and mDNS
  services.avahi.enable = true;

  # User configuration is now handled by the users clanService
  # Additional user settings that aren't covered by the service:
  users.users.yatekii = {
    uid = 1000;
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
  };
}

{ config, ... }:
{
  # clanModules have been migrated to clanServices in flake.nix inventory.instances:
  # - sshd
  # - users (replaces root-password and user-password)
  # - trusted-nix-caches

  # Locale service discovery and mDNS
  services.avahi.enable = true;

  # User configuration is now handled by the users clanService
  # Additional user settings that aren't covered by the service:
  users.users.yatekii = {
    uid = 1000;
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
  };

  # Passwordless sudo for wheel (yatekii). Acceptable trade-off: the only
  # entry points are (a) SSH key auth as yatekii/root and (b) physical
  # console. No password adds no meaningful barrier against an attacker
  # who already has shell as a wheel user.
  security.sudo.wheelNeedsPassword = false;
}

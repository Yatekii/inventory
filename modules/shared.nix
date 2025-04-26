{ config, clan-core, ... }: {
  imports = [
    # Enables the OpenSSH server for remote access
    clan-core.clanModules.sshd
    # Set a root password
    clan-core.clanModules.root-password
    clan-core.clanModules.user-password
    clan-core.clanModules.state-version

    clan-core.clanModules.trusted-nix-caches
  ];

  # clan.core.networking.buildHost = "yatekii@localhost";

  nix.settings.substituters = [ "https://attic.kennel.juneis.dog/conduwuit" ];
  nix.settings.trusted-public-keys =
    [ "conduit:eEKoUwlQGDdYmAI/Q/0slVlegqh/QmAvQd7HBSm21Wk=" ];

  # Locale service discovery and mDNS
  services.avahi.enable = true;

  # generate a random password for our user below
  # can be read using `clan secrets get <machine-name>-user-password` command
  clan.user-password.user = "yatekii";
  users.users.user = {
    name = "yatekii";
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    uid = 1000;
    openssh.authorizedKeys.keys =
      config.users.users.root.openssh.authorizedKeys.keys;
  };

  # domainNames = { matrix = "aiur.chat"; };
}

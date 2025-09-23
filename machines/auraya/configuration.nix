{ inputs, ... }: {
  imports = [
    inputs.home-manager.darwinModules
    #s../../flake/home/yatekii.nix
  ];

  clan.core.networking.targetHost = "root@localhost";
  nixpkgs.hostPlatform = "aarch64-darwin"; # Use "x86_64-darwin" for Intel-based Macs
  system.stateVersion = 6;

  security.pam.services.sudo_local.touchIdAuth = true;


}

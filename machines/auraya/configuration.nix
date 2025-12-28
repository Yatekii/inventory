{ self, lib, ... }:
let
  gatherModules = import ../../modules/flake/_gatherModules.nix;
in
{
  imports = [
    self.inputs.home-manager.darwinModules.default
    {
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = false;
      home-manager.verbose = true;
    }
    self.inputs.nix-homebrew.darwinModules.nix-homebrew
    ./homebrew.nix
    ./yatekii.nix
  ]
  ++ gatherModules lib [ ../../modules/flake/overlays ];

  # Used for clan to connect to the host when running any of the machine commands.
  clan.core.networking.targetHost = "yatekii@localhost";
  # We are on aarch64 (ARM) from now on.
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  system.primaryUser = "yatekii";

  # User configuration
  users.users.yatekii = {
    name = "yatekii";
    home = "/Users/yatekii";
  };

  # Home Manager configuration for yatekii
  home-manager.users.yatekii =
    { pkgs, ... }:
    {
      home.username = "yatekii";
      home.homeDirectory = "/Users/yatekii";
      home.stateVersion = "25.05";

      home.packages = [
        pkgs.htop
      ];
    };

  # Allow touch ID to be used for sudo password prompts.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Do not show the special/accented characters prompt on press and hold of characters.
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;

  homebrew.enable = true;

  # TODO: How can we move this to a module?
  # We use homebrew because the nixpkg is not available on darwin.
  homebrew.casks = [
    "vlc"
  ];
}

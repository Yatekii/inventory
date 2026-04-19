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
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/apps.nix
    ../../modules/darwin/users/yatekii.nix
  ]
  ++ gatherModules lib [ ../../modules/flake/overlays ];

  # Used for clan to connect to the host when running any of the machine commands.
  clan.core.networking.targetHost = "yatekii@localhost";
  # We are on aarch64 (ARM) from now on.
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  system.primaryUser = "yatekii";

  # Allow touch ID to be used for sudo password prompts.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Do not show the special/accented characters prompt on press and hold of characters.
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;

  system.defaults.NSGlobalDomain."com.apple.trackpad.forceClick" = false;
}

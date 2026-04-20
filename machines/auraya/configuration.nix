{ self, lib, ... }:
let
  gatherModules = import ../../modules/flake/gatherModules.nix;
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
  ]
  ++ gatherModules lib [ ../../modules/darwin ];

  # Used for clan to connect to the host when running any of the machine commands.
  clan.core.networking.targetHost = "yatekii@localhost";
  # We are on aarch64 (ARM) from now on.
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  system.primaryUser = "yatekii";
}

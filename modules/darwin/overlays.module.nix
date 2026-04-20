{ self, ... }:
let
  overlays = builtins.attrValues self.overlays;
in
{
  nixpkgs.overlays = overlays;

  # Propagate into HM's own nixpkgs because `useGlobalPkgs = false` gives HM
  # an isolated pkgs instance; sharedModules injects this config into every
  # HM user automatically.
  home-manager.sharedModules = [
    { nixpkgs.overlays = overlays; }
  ];
}

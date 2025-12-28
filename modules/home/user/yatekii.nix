{ lib, pkgs, ... }:
let
  gatherModules = import ../../flake/_gatherModules.nix;
in
{
  imports = gatherModules lib [ ./yatekii ];
  # This is a flake-parts module that defines home-manager modules
  # These can be imported in machine-specific home-manager configs

  home.packages = [
    pkgs.fzf
    pkgs.ripgrep
    pkgs.direnv
    pkgs.rectangle
  ];
}

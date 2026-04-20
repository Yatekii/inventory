{ lib, pkgs, ... }:
let
  gatherModules = import ../../flake/gatherModules.nix;
in
{
  imports = gatherModules lib [ ./yatekii ];
  # This is a flake-parts module that defines home-manager modules
  # These can be imported in machine-specific home-manager configs

  home.packages = [
    pkgs.fzf
    pkgs.ripgrep
    pkgs.direnv
    pkgs.bat
    pkgs.tokei
    pkgs.colima
    pkgs.docker-client
    pkgs.docker-compose
    pkgs.ansible
    pkgs.bazel
    pkgs.rbw
    pkgs.bzip2
    pkgs.dua
    pkgs.ffmpeg
    pkgs.mcap-cli
    pkgs.ncdu
    pkgs.restic
    pkgs.trunk
  ];
}

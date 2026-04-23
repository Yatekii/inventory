{ lib, pkgs, ... }:
let
  gatherModules = import ../../flake/gatherModules.nix;
  # Modules under yatekii/desktop/ only apply to a machine a person sits at
  # (launchd agents, GUI app config). They're excluded here so this aggregator
  # stays portable across darwin and nixos; the per-machine user module
  # (e.g. modules/darwin/users/yatekii.module.nix) re-adds them on hosts that
  # want them. Don't gate on pkgs.stdenv.isDarwin here — referencing pkgs
  # inside `imports` causes infinite recursion through _module.args.
  all = gatherModules lib [ ./yatekii ];
  portable = lib.filter (p: !lib.hasInfix "/desktop/" (toString p)) all;
in
{
  imports = portable;
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
    pkgs.probe-rs-tools
    pkgs.restic
    pkgs.trunk
  ];
}

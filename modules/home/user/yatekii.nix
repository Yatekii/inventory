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
    pkgs.bat
  ];

  launchd.agents.rectangle = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.rectangle}/Applications/Rectangle.app/Contents/MacOS/Rectangle" ];
      RunAtLoad = true;
      KeepAlive = false;
      ProcessType = "Interactive";
    };
  };
}

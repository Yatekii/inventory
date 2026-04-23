{ lib, ... }:
let
  gatherModules = import ../../flake/gatherModules.nix;
in
{
  users.users.yatekii = {
    name = "yatekii";
    home = "/Users/yatekii";
  };

  home-manager.users.yatekii =
    { pkgs, ... }:
    {
      # Pull in the portable yatekii config, then layer on the desktop-only
      # modules (launchd-managed apps, GUI tools). NixOS hosts import
      # yatekii.nix without this extra gather so they stay server-shaped.
      imports = [
        ../../home/user/yatekii.nix
      ]
      ++ gatherModules lib [ ../../home/user/yatekii/desktop ];
      home.username = "yatekii";
      home.homeDirectory = "/Users/yatekii";
      home.stateVersion = "25.05";
      programs.bash.enable = true;
    };
}

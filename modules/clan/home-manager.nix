{ self, lib, ... }:
let
  gatherModules = import ../flake/gatherModules.nix;
in
{
  imports = [
    self.inputs.home-manager.nixosModules.default
  ];

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = false;
  home-manager.verbose = true;
  # Rename pre-existing files HM would refuse to clobber instead of failing
  # activation on first deploy (mirrors the darwin setup in auraya).
  home-manager.backupFileExtension = "bak";

  home-manager.users.yatekii =
    { ... }:
    {
      imports = [
        ../home/user/yatekii.nix
      ];
      home.username = "yatekii";
      home.homeDirectory = "/home/yatekii";
      home.stateVersion = "25.05";
      programs.bash.enable = true;
    };

  # Root gets the same shared HM shell as yatekii (atuin, starship, eza, ...)
  # so `ssh root@host` lands in the same environment. No yatekii-specific
  # personal modules (git config, editor prefs, etc.) — just the shell.
  home-manager.users.root =
    { ... }:
    {
      imports = gatherModules lib [ ../home/shared ];
      home.username = "root";
      home.homeDirectory = "/root";
      home.stateVersion = "25.05";
      programs.bash.enable = true;
    };
}

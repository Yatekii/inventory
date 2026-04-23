{ self, ... }:
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
}

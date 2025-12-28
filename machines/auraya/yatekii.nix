{ self, pkgs, ... }:
{
  users.users.yatekii = {
    name = "yatekii";
    home = "/Users/yatekii";
  };

  home-manager.extraSpecialArgs = { inherit self; };
  home-manager.users.yatekii =
    { pkgs, ... }:
    {
      imports = [
        ../../modules/home/user/yatekii.nix
      ];
      home.packages = [
        pkgs.atool
        pkgs.httpie
      ];
      programs.bash.enable = true;

      # The state version is required and should stay at the version you
      # originally installed.
      home.stateVersion = "25.05";
    };
}

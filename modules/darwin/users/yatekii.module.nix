{ ... }:
{
  users.users.yatekii = {
    name = "yatekii";
    home = "/Users/yatekii";
  };

  home-manager.users.yatekii =
    { pkgs, ... }:
    {
      imports = [
        ../../home/user/yatekii.nix
      ];
      home.username = "yatekii";
      home.homeDirectory = "/Users/yatekii";
      home.stateVersion = "25.05";
      programs.bash.enable = true;
    };
}

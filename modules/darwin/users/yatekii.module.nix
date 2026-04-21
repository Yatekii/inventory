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
      home.packages = [
        pkgs.atool
        pkgs.httpie
        pkgs.probe-rs-tools
      ];
      programs.bash.enable = true;
    };
}

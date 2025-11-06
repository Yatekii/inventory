{ inputs, ... }:
let
  pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin.pkgs;
in
{
  # users.users.yatekii = {
  #   name = "yatekii";
  #   home = "/Users/yatekii";
  # };

  # home-manager.extraSpecialArgs = {
  #   # inherit self;
  # };

  # home-manager.yatekii =
  #   { pkgs, ... }:
  #   {
  #     # Home Manager needs a bit of information about you and the
  #     # paths it should manage.
  #     home.username = "yatekii";
  #     home.homeDirectory = "/Users/yatekii";

  #     # imports = self.lib.collectModules ./modules;

  #     # This value determines the Home Manager release that your
  #     # configuration is compatible with. This helps avoid breakage
  #     # when a new Home Manager release introduces backwards
  #     # incompatible changes.
  #     #
  #     # You can update Home Manager without changing this value. See
  #     # the Home Manager release notes for a list of state version
  #     # changes in each release.
  #     home.stateVersion = "25.05";

  #     # Let Home Manager install and manage itself.
  #     programs.home-manager.enable = true;

  #     home.packages = [
  #       pkgs.ripgrep
  #       # pkgs.bat
  #       pkgs.direnv
  #       pkgs.fzf
  #     ];
  #   };
  # home.packages = [
  #   pkgs.htop
  #   pkgs.fortune
  # ];

  flake = {
    users.users.yatekii = {
      name = "yatekii";
      home = "/Users/yatekii";
    };
    home.packages = [
      pkgs.htop
      pkgs.fortune
    ];
  };
}

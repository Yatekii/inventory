{ pkgs, ... }:
{
  flake.modules = {
    home.packages = [
      pkgs.eza
    ];

    home.shellAliases = {
      l = "eza -algM --git --git-repos-no-status";
    };
  };
}

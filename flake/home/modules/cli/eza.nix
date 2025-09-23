# eza -algM --git --git-repos-no-status
{ pkgs, ... }:
{
  home.packages = [
    pkgs.eza
  ];
}

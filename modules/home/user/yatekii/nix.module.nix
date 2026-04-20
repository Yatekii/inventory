{ pkgs, ... }:
{
  home.packages = [
    pkgs.nixfmt
    pkgs.nil
    pkgs.nixd
  ];
}

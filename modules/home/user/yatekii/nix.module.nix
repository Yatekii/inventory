{ pkgs, ... }:
{
  home.packages = [
    pkgs.nixfmt-rfc-style
    pkgs.nil
    pkgs.nixd
  ];
}

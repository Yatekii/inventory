{ pkgs, ... }:
{
  flake.modules.home.packages = [
    pkgs.nixfmt-rfc-style
    pkgs.nil
  ];
}

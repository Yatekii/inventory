{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.ncdu ];
}

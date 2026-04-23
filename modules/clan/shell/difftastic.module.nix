{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.difftastic ];
}

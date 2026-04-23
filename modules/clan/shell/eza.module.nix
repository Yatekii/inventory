{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.eza ];

  environment.shellAliases = {
    l = "eza -algM --git --git-repos-no-status";
  };
}

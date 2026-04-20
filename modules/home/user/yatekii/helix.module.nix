{ ... }:
let
  helixSettings = import ../../../helix-settings.nix;
in
{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = helixSettings.settings;
  };
}

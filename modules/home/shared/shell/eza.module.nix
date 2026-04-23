{ pkgs, ... }:
let
  # `vivid` renders an LS_COLORS string from a named theme. eza reads
  # LS_COLORS as a fallback when EZA_COLORS isn't set, so `l` (eza)
  # and any other ls-family tool share one gruvbox palette. Generated
  # at build time, loaded into the shell env once per session.
  gruvboxLsColors = pkgs.runCommand "gruvbox-ls-colors" { } ''
    ${pkgs.vivid}/bin/vivid generate gruvbox-dark > $out
  '';
in
{
  home.packages = [
    pkgs.eza
  ];

  home.shellAliases = {
    l = "eza -algM --git --git-repos-no-status";
  };

  home.sessionVariablesExtra = ''
    export LS_COLORS="$(cat ${gruvboxLsColors})"
  '';
}

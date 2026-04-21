{ pkgs, ... }:
{
  # Nerd-patched Hack so starship's prompt glyphs render. home-manager
  # drops the fonts into the OS-appropriate location (~/Library/Fonts on
  # darwin, XDG/fontconfig-indexed dirs on linux), so this one line covers
  # both platforms — you still need to select the font in your terminal.
  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
}

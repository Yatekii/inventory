{ ... }:
{
  homebrew.enable = true;

  # Packages not available in nixpkgs for darwin, installed via Homebrew.
  homebrew.casks = [
    "vlc"
    "caffeine"
    "macfuse"
    "claude-code@latest"
    "gimp"
    "kicad"
    "stats"
    "rectangle"
    "zed"
    "ghostty"
  ];

  homebrew.brews = [
    "act"
  ];
}

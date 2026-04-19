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
  ];

  homebrew.brews = [
    "act"
  ];
}

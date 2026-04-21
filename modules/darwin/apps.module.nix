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
    "raycast"
    # karabiner-elements: install manually with `brew install --cask karabiner-elements`.
    # Its .pkg installer needs an interactive sudo prompt that brew bundle can't provide
    # during `clan machines update` (no TTY, and pam_tid can't prompt over a pipe either).
  ];

  homebrew.brews = [
    "act"
  ];
}

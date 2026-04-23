{ ... }:
{
  # System-level starship prompt for every user. Prompt config lives
  # alongside this module in native TOML so it round-trips cleanly with
  # upstream references; Nix parses and serializes back to /etc/starship.toml.
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
}

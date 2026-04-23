{ ... }:
{
  # Prompt config lives next to this module in its native TOML form so it
  # round-trips cleanly with upstream references. Nix parses it and hands
  # the attrset to home-manager, which serializes back to ~/.config/starship.toml.
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
}

{ ... }:
{
  # Shared starship prompt, same TOML yatekii's home-manager consumes.
  # Prompt config lives next to yatekii's module so it round-trips cleanly
  # with upstream references; Nix parses and hands the attrset to NixOS,
  # which serializes back to /etc/starship.toml.
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (
      builtins.readFile ../../home/user/yatekii/shell/starship.toml
    );
  };
}

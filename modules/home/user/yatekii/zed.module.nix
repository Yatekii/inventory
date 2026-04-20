{ ... }:
{
  # Zed itself is installed as a Homebrew cask via modules/darwin/apps.nix so
  # Spotlight can index it and macOS can track its code signature stably
  # across rebuilds. We still manage settings declaratively here.
  xdg.configFile."zed/settings.json".text = builtins.toJSON {
    theme = {
      mode = "system";
      dark = "Gruvbox Dark Hard";
      light = "Gruvbox Light Hard";
    };
    hour_format = "hour24";
    auto_install_extensions = {
      html = true;
      ini = true;
      nix = true;
      rust = true;
      terraform = true;
      toml = true;
    };
  };
}

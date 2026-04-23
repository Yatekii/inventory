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
    icon_theme = {
      mode = "dark";
      light = "Zed (Default)";
      dark = "Zed (Default)";
    };
    ui_font_size = 16;
    buffer_font_size = 15;
    hour_format = "hour24";
    format_on_save = "on";
    show_edit_predictions = false;
    scrollbar.git_diff = false;
    terminal.dock = "right";
    toolbar.agent_review = true;
    telemetry = {
      diagnostics = false;
      metrics = false;
    };
    agent = {
      default_model = {
        provider = "anthropic";
        model = "claude-sonnet-4-5-latest";
      };
      dock = "right";
      button = true;
    };
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

{ pkgs, ... }:
{
  programs.zed-editor = {
    package = pkgs.zed-editor;
    enable = true;
    extensions = [
      "html"
      "ini"
      "nix"
      "rust"
      "terraform"
      "toml"
    ];
    userSettings = {
      theme = {
        mode = "system";
        dark = "Gruvbox Dark Hard";
        light = "Gruvbox Light Hard";
      };
      hour_format = "hour24";
    };
  };
}

{ ... }:
{
  # Ghostty itself is installed as a Homebrew cask via modules/darwin/apps.module.nix
  # so macOS gets the signed build with native Spotlight indexing. On Linux the
  # package manager equivalent lives elsewhere. We only manage the config file
  # here — Ghostty reads $XDG_CONFIG_HOME/ghostty/config on both platforms.
  xdg.configFile."ghostty/config".text = ''
    font-family = JetBrainsMono Nerd Font Mono
    font-size = 14
    adjust-cell-height = 15%

    theme = Gruvbox Dark Hard

    cursor-style = block
    cursor-style-blink = false

    window-padding-x = 8
    window-padding-y = 8
    window-save-state = always

    copy-on-select = clipboard
    confirm-close-surface = false

    macos-option-as-alt = true
    macos-titlebar-style = tabs

    shell-integration = detect
    shell-integration-features = cursor,sudo,title
  '';
}

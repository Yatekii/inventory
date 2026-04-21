{ ... }:
{
  system.defaults.NSGlobalDomain = {
    # Do not show the special/accented characters prompt on press-and-hold.
    ApplePressAndHoldEnabled = false;

    "com.apple.trackpad.forceClick" = false;

    # Fast key repeat. 2 is the fastest selectable via System Settings;
    # InitialKeyRepeat = 15 = 225ms before repeat kicks in.
    KeyRepeat = 2;
    InitialKeyRepeat = 15;

    # Show all file extensions; stop macOS from second-guessing them.
    AppleShowAllExtensions = true;

    # Expand save/print panels by default — no more clicking the tiny arrow.
    NSNavPanelExpandedStateForSaveMode = true;
    NSNavPanelExpandedStateForSaveMode2 = true;
    PMPrintingExpandedStateForPrint = true;
    PMPrintingExpandedStateForPrint2 = true;

    # Disable autocorrect/substitutions that mangle code and commit messages.
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
  };

  system.defaults.finder = {
    AppleShowAllFiles = true;
    ShowPathbar = true;
    ShowStatusBar = true;
    FXPreferredViewStyle = "Nlsv"; # list view
    FXDefaultSearchScope = "SCcf"; # search current folder by default
    _FXSortFoldersFirst = true;
  };

  system.defaults.dock = {
    autohide = true;
    tilesize = 48;
    mru-spaces = false; # keep spaces in a fixed order
    show-recents = false;
  };

  # Screenshots land in ~/Pictures/screenshots as PNG, no drop-shadow.
  # screencapture silently falls back to ~/Desktop if the target directory
  # doesn't exist, so postActivation below guarantees it exists before the
  # defaults take effect on the next screenshot.
  system.defaults.screencapture = {
    location = "~/Pictures/screenshots";
    type = "png";
    disable-shadow = true;
  };
  # All nix-darwin activation now runs as root (postUserActivation was
  # removed). `sudo -u yatekii` drops back to the user so the dir is owned
  # by them and `~` expands correctly. Custom attribute names (e.g.
  # .screenshotsDir) don't auto-run — only the pre-defined hooks
  # (preActivation, extraActivation, postActivation) are wired into the
  # darwin activation graph.
  system.activationScripts.postActivation.text = ''
    sudo -u yatekii mkdir -p /Users/yatekii/Pictures/screenshots
  '';

  # Stop Finder from littering .DS_Store on network shares and USB drives.
  system.defaults.CustomUserPreferences."com.apple.desktopservices" = {
    DSDontWriteNetworkStores = true;
    DSDontWriteUSBStores = true;
  };

  # Disable Spotlight's ⌘Space and ⌥⌘Space hotkeys so Raycast can claim ⌘Space.
  # Keys 64/65 are Apple's symbolic hotkey IDs for "Show Spotlight search" and
  # "Show Finder search window". The nested dict shape matches what macOS writes
  # to com.apple.symbolichotkeys.plist.
  system.defaults.CustomUserPreferences."com.apple.symbolichotkeys" = {
    AppleSymbolicHotKeys = {
      "64" = {
        enabled = false;
      };
      "65" = {
        enabled = false;
      };
    };
  };
}

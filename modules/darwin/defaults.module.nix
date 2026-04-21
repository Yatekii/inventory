{ ... }:
{
  # Do not show the special/accented characters prompt on press-and-hold.
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;

  system.defaults.NSGlobalDomain."com.apple.trackpad.forceClick" = false;

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

{
  # Shared helix configuration consumed by both the home-manager module
  # (modules/home/user/yatekii/helix.nix) on darwin and the NixOS system
  # module (modules/clan/helix.nix) on aiur/fenix. Keep this file free of
  # user- or system-specific knobs so a single change propagates everywhere.
  settings = {
    theme = "gruvbox_dark_hard";

    editor = {
      line-number = "relative";
      mouse = false;
      cursorline = true;
      color-modes = true;
      bufferline = "multiple";
      auto-format = true;
      auto-save = false;
      completion-trigger-len = 1;
      true-color = true;
      rulers = [ 100 ];

      cursor-shape = {
        insert = "bar";
        normal = "block";
        select = "underline";
      };

      file-picker = {
        hidden = false;
      };

      indent-guides = {
        render = true;
        character = "╎";
      };

      lsp = {
        display-messages = true;
        display-inlay-hints = true;
      };

      statusline = {
        left = [
          "mode"
          "spinner"
          "version-control"
          "file-name"
          "file-modification-indicator"
        ];
        center = [ ];
        right = [
          "diagnostics"
          "selections"
          "register"
          "position"
          "file-encoding"
          "file-line-ending"
          "file-type"
        ];
      };
    };
  };
}

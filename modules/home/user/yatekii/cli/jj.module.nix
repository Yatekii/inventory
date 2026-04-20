{ ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Noah Hüsser";
        email = "noah@huesser.dev";
      };
      ui.default-command = "log";
      ui.diff-formatter = [
        "difft"
        "--color=always"
        "$left"
        "$right"
      ];
    };
  };
}

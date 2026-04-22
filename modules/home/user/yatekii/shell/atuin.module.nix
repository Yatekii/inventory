{ ... }:
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = {
      # Up-arrow scrolls only the current session's commands so the prompt
      # doesn't jump to whatever you ran in another terminal. Ctrl-R still
      # opens the full merged history (filter_mode default = "global"),
      # and every command is recorded to the shared DB regardless of which
      # filter is active at recall time.
      filter_mode_shell_up_key_binding = "session";
    };
  };
}

{ pkgs, ... }:
let
  atuinConfig = (pkgs.formats.toml { }).generate "atuin-config.toml" {
    # Up-arrow scrolls only the current session's commands so the prompt
    # doesn't jump to whatever you ran in another terminal. Ctrl-R still
    # opens the full merged history (filter_mode default = "global"),
    # and every command is recorded to the shared DB regardless of which
    # filter is active at recall time. Mirrors yatekii's home-manager
    # atuin.module.nix so root and yatekii behave the same.
    filter_mode_shell_up_key_binding = "session";
  };
in
{
  # Atuin for root + any user without home-manager wiring. nixpkgs has no
  # system-level `programs.atuin`, so shell integration is wired manually.
  # Per-user SQLite history at ~/.local/share/atuin; no sync configured.
  environment.systemPackages = [ pkgs.atuin ];

  programs.bash.interactiveShellInit = ''
    eval "$(${pkgs.atuin}/bin/atuin init bash)"
  '';
  programs.zsh.interactiveShellInit = ''
    eval "$(${pkgs.atuin}/bin/atuin init zsh)"
  '';

  # Shared atuin config for root. Other users get defaults unless they
  # set up ~/.config/atuin/ themselves (yatekii does so via home-manager).
  systemd.tmpfiles.rules = [
    "d /root/.config 0700 root root -"
    "d /root/.config/atuin 0700 root root -"
    "L+ /root/.config/atuin/config.toml - - - - ${atuinConfig}"
  ];
}

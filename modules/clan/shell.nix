{ pkgs, ... }:
let
  atuinConfig = (pkgs.formats.toml { }).generate "atuin-config.toml" {
    filter_mode_shell_up_key_binding = "session";
  };
in
{
  # System-level CLI tooling for any shell user (root + yatekii, etc).
  # Mirrors the subset of yatekii's home-manager setup that's generally
  # useful for every session — enough that `ssh root@host` doesn't feel
  # like a stripped-down environment. yatekii's home-manager layer adds
  # the rest (direnv, jj, etc.) on top.
  environment.systemPackages = with pkgs; [
    eza
    bat
    ripgrep
    fd
    fzf
    zoxide
    difftastic
    bottom
    tokei
    jq
    ncdu
    atuin
  ];

  # Shared starship prompt config, same TOML yatekii's home-manager uses.
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../home/user/yatekii/shell/starship.toml);
  };

  # atuin shell integration for every user's interactive bash/zsh. No
  # system-level `programs.atuin` exists in nixpkgs, so wire it manually.
  # Each user ends up with their own local SQLite history at
  # ~/.local/share/atuin; no sync configured.
  programs.bash.interactiveShellInit = ''
    eval "$(${pkgs.atuin}/bin/atuin init bash)"
  '';
  programs.zsh.interactiveShellInit = ''
    eval "$(${pkgs.atuin}/bin/atuin init zsh)"
  '';

  # Shared atuin config for root (matches yatekii's session-filter). Other
  # users get defaults unless they set up their own ~/.config/atuin/.
  systemd.tmpfiles.rules = [
    "d /root/.config 0700 root root -"
    "d /root/.config/atuin 0700 root root -"
    "L+ /root/.config/atuin/config.toml - - - - ${atuinConfig}"
  ];

  environment.shellAliases = {
    l = "eza -algM --git --git-repos-no-status";
  };
}

{ pkgs, ... }:
{
  # System-level CLI tooling for any shell user (root + yatekii, etc).
  # Mirrors the subset of yatekii's home-manager setup that's generally
  # useful for every session — enough that `ssh root@host` doesn't feel
  # like a stripped-down environment. yatekii's home-manager layer adds
  # the rest (atuin, direnv, jj, etc.) on top.
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
  ];

  # Shared starship prompt config, same TOML yatekii's home-manager uses.
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../home/user/yatekii/shell/starship.toml);
  };

  environment.shellAliases = {
    l = "eza -algM --git --git-repos-no-status";
  };
}

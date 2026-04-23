{ pkgs, ... }:
let
  helixSettings = import ../helix-settings.nix;
  configToml = (pkgs.formats.toml { }).generate "helix-config.toml" helixSettings.settings;
in
{
  environment.systemPackages = [ pkgs.helix ];

  environment.variables.EDITOR = "hx";

  # Helix only reads config from $XDG_CONFIG_HOME/helix/config.toml (no
  # system-wide fallback), so drop a symlink into root's config dir pointing
  # at the store path. tmpfiles keeps it in sync after each activation.
  # yatekii's helix config is managed by home-manager now
  # (modules/home/user/yatekii/helix.module.nix) — we only cover root here
  # so `ssh root@host` still launches hx with the shared theme.
  systemd.tmpfiles.rules = [
    "d /root/.config 0700 root root -"
    "d /root/.config/helix 0700 root root -"
    "L+ /root/.config/helix/config.toml - - - - ${configToml}"
  ];
}

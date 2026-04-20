{ pkgs, ... }:
let
  helixSettings = import ../helix-settings.nix;
  configToml = (pkgs.formats.toml { }).generate "helix-config.toml" helixSettings.settings;
in
{
  environment.systemPackages = [ pkgs.helix ];

  environment.variables.EDITOR = "hx";

  # Helix only reads config from $XDG_CONFIG_HOME/helix/config.toml (no
  # system-wide fallback), so drop a symlink into each interactive user's
  # config dir pointing at the store path. tmpfiles keeps the links in sync
  # after each activation, so updating helix-settings.nix and redeploying
  # is enough to propagate changes.
  systemd.tmpfiles.rules = [
    "d /root/.config 0700 root root -"
    "d /root/.config/helix 0700 root root -"
    "L+ /root/.config/helix/config.toml - - - - ${configToml}"

    "d /home/yatekii/.config 0755 yatekii users -"
    "d /home/yatekii/.config/helix 0755 yatekii users -"
    "L+ /home/yatekii/.config/helix/config.toml - - - - ${configToml}"
  ];
}

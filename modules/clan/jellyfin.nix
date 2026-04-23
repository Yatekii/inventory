{ ... }:
let
  jellyfin-domain = "jellyfin.huesser.dev";
  jellyfin-host = "127.0.0.1";
  jellyfin-port = 8096;
in
{
  services.jellyfin = {
    enable = true;
    # Caddy-fronted, no direct LAN exposure needed.
    openFirewall = false;
  };

  # Jellyfin needs to read media from /saru/media (group-owned by `users`,
  # 0775). Adding the jellyfin service user to `users` grants read access
  # without relaxing permissions on the share.
  users.users.jellyfin.extraGroups = [ "users" ];

  services.caddy.virtualHosts."${jellyfin-domain}".extraConfig = ''
    reverse_proxy ${jellyfin-host}:${toString jellyfin-port}
  '';

  # State lives under /var/lib/jellyfin. Declaring it here so the eventual
  # clan backup service picks it up the same way vaultwarden does.
  # Excludes cache/logs/transcoding-tmp (all regeneratable, would otherwise
  # dominate the backup).
  clan.core.state.jellyfin = {
    folders = [ "/var/lib/jellyfin" ];
  };
}

{ ... }:
let
  immich-domain = "immich.huesser.dev";
  immich-host = "127.0.0.1";
  immich-port = 2283;
in
{
  services.immich = {
    enable = true;
    host = immich-host;
    port = immich-port;
    # Photos live on the ZFS pool, Docker-era layout preserved. Immich
    # writes uploads, thumbs, encoded-video, backups and profile pics
    # under this root — the same tree the Docker version used, so
    # existing thumbs/encoded assets keep their paths.
    mediaLocation = "/saru/media/photos";
    # Native NixOS brings Postgres (with vectorchord extension for ML
    # embeddings) + Redis + the ML sidecar, replacing the four Docker
    # containers the ansible-nas role ran.
    database.enable = true;
    redis.enable = true;
    machine-learning.enable = true;
    # Caddy-fronted, no direct LAN exposure.
    openFirewall = false;
  };

  # Same trick as jellyfin: immich needs to read/write under
  # /saru/media/photos (group `users`, 0775).
  users.users.immich.extraGroups = [ "users" ];

  # Photos + videos can be large; allow a generous upload ceiling. Caddy's
  # default is effectively unlimited for reverse_proxy, but we set it
  # explicitly so future changes don't accidentally cap it.
  services.caddy.virtualHosts."${immich-domain}".extraConfig = ''
    request_body {
      max_size 50GB
    }
    reverse_proxy ${immich-host}:${toString immich-port}
  '';

  # State backup contract. Photos themselves are on saru/media/photos
  # (ZFS dataset, captured by the pool-level backup). Here we cover
  # immich's own state dir + provide a pre-backup hook to dump Postgres
  # consistently while the service is running.
  clan.core.state.immich = {
    folders = [ "/var/lib/immich" ];
  };
}

# saru service backup matrix

Per-service authoritative list of what to back up and how to restore. Cross-
checked against `docker inspect` mounts on saru + official docs (where
accessible). Referenced by [PORT-PLAN.md](PORT-PLAN.md).

## Mount-table ground truth (from `docker inspect`)

All services store their state entirely under `/opt/docker/<svc>/` via bind
mounts. Anonymous Docker volumes exist but were verified to contain either
empty directories, stale pre-bind state, or regeneratable caches — **no
anonymous volume holds critical state**. Detailed notes per service below.

## Per-service

### Jellyfin

- **Mount**: `/opt/docker/jellyfin/config` → `/config`. Media bind-mounted
  from ZFS (already covered by ZFS snapshots).
- **State to back up** (all under `/opt/docker/jellyfin/config/`):
  - `data/data/jellyfin.db`, `data/data/users.db`, `data/data/activitylog.db`
    — SQLite DBs. Capture via host `sqlite3 .backup` to consistent paths.
  - `data/` — metadata, plugins, plugin configs, trickplay, extracted
    subtitles.
  - `config/` — system.xml, network.xml, encoding.xml.
  - `log/` — skip (regeneratable).
  - `cache/` — skip (regeneratable).
  - `metadata/` — keep (user-curated images/NFOs).
- **Critical**: the 3 DBs + `config/` (auth + network settings). Without DBs
  you lose libraries, users, watch state. Without config you relose server-
  level settings.
- **Regenerates**: cache, log, transcoding temp.
- **Restore**: stop jellyfin → `rsync` entire config dir back to
  `/var/lib/jellyfin/` (NixOS path) → replace the 3 DBs with our
  `.backup`-consistent copies → `chown jellyfin:jellyfin -R` → start.

### Sonarr

- **Mount**: `/opt/docker/sonarr/config` → `/config`.
- **Actual directory contents** (verified on saru): `sonarr.db`,
  `sonarr.db-{shm,wal}`, `config.xml`, `sonarr.pid`, `logs.db`,
  `logs.db-{shm,wal}`, `asp/`, `Backups/`, `logs/`, `MediaCover/`,
  `Sentry/`, `custom-cont-init.d/`, `custom-services.d/`.
- **Keep**:
  - `sonarr.db` — main SQLite DB (libraries, series, episodes, history,
    indexer configs, download client configs, quality profiles). Capture
    via `sqlite3 .backup`.
  - `config.xml` — **API key, auth config, URL base, bind address**.
  - `asp/` — ASP.NET Core data-protection keys used to encrypt session
    cookies. Re-created if missing (just logs everyone out), but cheap to
    preserve.
- **Skip**: `logs.db*`, `Backups/` (service-native ZIPs we chose not to
  use), `logs/`, `MediaCover/`, `Sentry/`, `custom-*` (linuxserver.io
  container init scripts, re-created), `*.pid`.
- **Critical**: `sonarr.db` + `config.xml` (the API key — losing it means
  every Prowlarr/Radarr/Bazarr/Jellyseer integration has to be re-configured
  with a new key).
- **Restore**: stop sonarr → place `config.xml` + `asp/` + our
  `.backup`-consistent `sonarr.db` into `/var/lib/sonarr/` (NixOS path) →
  chown → start.

### Radarr

- **Mount**: `/opt/docker/radarr` → `/config` (note: **top-level**, no
  `config/` subdir).
- **Actual directory contents** (verified): same structure as Sonarr —
  `radarr.db` + `radarr.db-{shm,wal}`, `config.xml`, `asp/`, `Backups/`,
  `logs/`, `logs.db*`, `MediaCover/`, `Sentry/`, `radarr.pid`.
- **Keep**: `radarr.db` (via `.backup`), `config.xml`, `asp/`.
- **Skip**: same as Sonarr.
- **Critical / restore**: same as Sonarr. NixOS path: `/var/lib/radarr/`.

### Bazarr

- **Mount**: `/opt/docker/bazarr/config` → `/config`.
- **State** (under `/opt/docker/bazarr/config/`):
  - `db/bazarr.db` — SQLite DB (subtitle state, user preferences, connected
    providers). Capture via `sqlite3 .backup`.
  - `config/config.ini` — settings including API keys for OpenSubtitles
    etc., Sonarr/Radarr endpoints.
  - `log/` — skip.
- **Critical**: the DB + `config.ini` (provider credentials).
- **Restore**: stop bazarr → place DB + config.ini at NixOS path → chown.

### Jackett

- **Mount**: `/opt/docker/jackett/config` → `/config`.
- **State** (under `/opt/docker/jackett/config/Jackett/`):
  - `ServerConfig.json` — API key, password, cookie secret, port.
  - `Indexers/*.json` — per-configured-indexer JSON with cookies and
    credentials.
- **Critical**: ServerConfig.json + Indexers/ directory. No SQLite.
- **Restore**: stop → drop files in place → chown.

### Transmission

- **Mount**: `/opt/docker/transmission/config` → `/config`.
- **State** (under `/opt/docker/transmission/config/`):
  - `settings.json` — download dir, RPC auth, speed limits.
  - `torrents/` — `.torrent` files for every active download.
  - `resume/` — per-torrent resume data (checksums, progress).
  - `stats.json` — lifetime stats.
  - `dht.dat`, `blocklists/` — regeneratable.
- **Critical**: torrents/, resume/, settings.json. Without resume/ all
  downloads restart from scratch.
- **Restore**: stop → copy all of it → chown.

### Vaultwarden

- **Mount**: `/opt/docker/bitwarden` → `/data` (note: **top-level**, no
  `data/` subdir — I had this wrong in an earlier draft).
- **State** (under `/opt/docker/bitwarden/`):
  - `db.sqlite3` — main vault DB. Capture via `sqlite3 .backup`.
  - `db.sqlite3-wal` — SQLite WAL. **Do not** include in restic if using
    our `.backup`-consistent dump for restore (the consistent DB is
    self-contained). Include in restic for a belt-and-braces raw copy.
  - `attachments/` — per-attachment files.
  - `sends/` — Bitwarden Send attachments (ephemeral, but preserve for
    in-flight sends).
  - `rsa_key.der`, `rsa_key.pem`, `rsa_key.pub.der`, `rsa_key.pub.pem` — **4
    JWT signing keys**. Losing them doesn't lose data, but logs every user
    out and invalidates every session.
  - `config.json` — admin panel config (**contains SMTP credentials** — 
    encrypt at rest).
  - `icon_cache/` — regeneratable.
- **Critical**: db.sqlite3 + attachments + rsa_key.{der,pem,pub.der,pub.pem}.
- **Post-1.32.1 alternative**: `docker exec vaultwarden /vaultwarden backup`
  is the official hot-backup command. Same effect as our `sqlite3 .backup`
  but service-blessed.
- **Restore**: stop vaultwarden → copy files to `/var/lib/vaultwarden/`
  (NixOS path) → `chown vaultwarden:vaultwarden -R` → start. Users will
  need to sign in once more (but vault content survives).

### Syncthing (single active instance)

- **Active instance**: `syncthing` only. The `syncthing-noah` and
  `syncthing-scans` containers are gone / deprecated — not carried forward.
- **Mounts**: `/opt/docker/syncthing` → `/var/syncthing/config`, plus
  `/saru/noah` + `/saru/scans` sync paths (ZFS datasets, already backed up
  via `restic_directories`). Anonymous Docker volume at `/var/syncthing/`
  (outside `config/`) verified to hold only stale pre-bind state. Skip.
- **State to back up** (under `/opt/docker/syncthing/`):
  - `cert.pem`, `key.pem` — **device identity. Irreplaceable.** SHA-256
    of the certificate IS the device ID. Lose them → must re-pair every
    peer.
  - `config.xml` — folder configs, device pairings, shared-with lists.
    Non-regeneratable.
  - `index-v2/` — content index DBs. Rebuildable via folder rescan (slow,
    but automatic). Skip unless we want faster restore — plain-dir entry
    captures it either way.
- **Critical**: cert.pem + key.pem + config.xml.
- **NixOS target**: clan-core `syncthing` clanService — restore means
  migrating the cert + key + folder IDs into the clanService config,
  not raw file-copy.

### Decommissioned / cleanup

- `saru/syncthing` ZFS dataset (196 KB, unused) — **delete pre-port**:
  `zfs destroy saru/syncthing`.
- `/opt/docker/syncthing-noah`, `/opt/docker/syncthing-scans` — `rm -rf`
  after confirming the containers are truly gone.
- `/opt/docker/{dim,heimdall,paperless_ngx,portainer}` — user-confirmed
  dropped; `rm -rf` after cutover.

### Zitadel

- **Mounts**:
  - `zitadel` (app): `/opt/docker/zitadel/config` → `/config`.
  - `zitadel-postgres`: `/opt/docker/zitadel/postgres` →
    `/var/lib/postgresql/data`.
- **Actual config dir contents** (verified): `config.yaml`, `init.yaml`.
- **State**:
  - Postgres DB — **the state**. Zitadel is event-sourced; everything can
    be replayed from `eventstore.events`. `pg_dumpall` already in pre-hook.
  - `config/config.yaml` + `config/init.yaml` — external domain, TLS mode,
    SMTP policy, token lifetimes, customizations.
  - **Masterkey** — passed as `--masterkey` CLI argument on container start
    (verified via `docker inspect`; **not in a file on disk**). Value
    lives in the ansible-nas run command template; already in
    `inventories/saru/group_vars/nas/vault.yml`. Used to encrypt secrets
    at rest in the DB.
- **Critical**: Postgres dump + masterkey + config YAML.
- **Regenerates**: nothing (event-sourced).
- **Restore on NixOS**:
  1. Start NixOS-hosted Postgres container, restore from `pg_dumpall`.
  2. Start Zitadel container with **the same masterkey** (supplied via
     clan.core.vars generator; seed with the current vault value at port
     time).
  3. Restore `config.yaml` + `init.yaml` to the mount point.
  4. Postgres DB contents decrypt correctly only with the matching
     masterkey.

### Immich

- **Mounts**:
  - `immich-server`: `/opt/docker/immich/config` → `/config` + `/saru/media/photos`
    → `/usr/src/app/upload`. Anonymous volume at `/data` — verified empty,
    skip.
  - `immich-postgres`: `/opt/docker/immich/postgres` → `/var/lib/postgresql/data`.
  - `immich-ml`: `/opt/docker/immich/model-cache` → `/cache` (regeneratable).
  - `immich-redis`: anonymous volume holding `dump.rdb` (job queue state,
    regeneratable on restart — some in-flight jobs lost).
- **State to back up**:
  - Postgres DB — `pg_dumpall` pre-hook already in place. **Include
    vectorchord extension** when restoring (the pg_dumpall output references
    it).
  - `/saru/media/photos` — already covered by the existing
    `restic_directories` for `saru/media` with `directory: photos`.
  - `/opt/docker/immich/config/` — small config (env vars, custom branding).
- **Regenerates**: thumbs, encoded-video, ML model cache, Redis queue.
- **Restore**: restore Postgres (create vectorchord extension first) →
  place config → point at existing `/saru/media/photos` → start server →
  re-run thumbnail + transcode jobs from admin UI.

### Headscale

- **Mount**: `/opt/docker/headscale/config` → `/etc/headscale`.
- **Actual directory contents** (verified on saru): `config.yaml`,
  `db.sqlite`, `noise_private.key`, `private.key`. **No
  `derp_server_private.key`** — saru isn't running its own DERP; using
  external relays.
- **Keep all 4 files**:
  - `db.sqlite` — all machine registrations, API keys, routes. Capture via
    `sqlite3 .backup`.
  - `noise_private.key` — Noise protocol identity. Irreplaceable; if lost
    all nodes must re-register against a fresh identity.
  - `private.key` — legacy server key (historical TLS identity; headscale
    keeps it for machine key compatibility).
  - `config.yaml` — server config (OIDC, DERP relay list, DNS).
- **Critical**: everything in the config dir.
- **Restore**: stop → place files → chown — clients reconnect to the same
  headscale identity, no re-registration needed.

### Jellyseer (Jellyseerr)

- **Mount**: `/opt/docker/jellyseer/config` → `/app/config`.
- **Actual directory contents** (verified): `db/` (with `db.sqlite3`),
  `logs/`, `settings.json`, `settings.old.json` (one-time backup Jellyseerr
  made during a prior upgrade).
- **Keep**:
  - `db/db.sqlite3` — users, requests, sessions. Capture via
    `sqlite3 .backup`.
  - `settings.json` — main config: Jellyfin URL + token, Sonarr + Radarr
    URLs + API keys, OIDC endpoints.
- **Skip**: `logs/`, `settings.old.json` (obsolete auto-snapshot).
- **Critical**: DB + settings.json.
- **Restore**: stop → place files → chown.

## Summary: final `restic_plain_directories` + pre-hooks

Proposed `vars.yml` diff — consolidates this matrix into ansible-nas config:

```yaml
restic_plain_directories:
  - /opt/docker/bitwarden          # existing — vaultwarden data incl rsa_key.*
  - /opt/restic/db-dumps           # existing — pg_dumpall outputs
  - /opt/docker/jellyfin/config    # jellyfin state
  - /opt/docker/sonarr/config      # sonarr state incl config.xml + API key
  - /opt/docker/radarr             # radarr state (top-level, no config/)
  - /opt/docker/bazarr/config      # bazarr state
  - /opt/docker/jackett/config     # jackett ServerConfig.json + Indexers/
  - /opt/docker/transmission/config # transmission settings + torrents/ + resume/
  - /opt/docker/syncthing          # syncthing cert + key + config.xml (single active instance)
  - /opt/docker/jellyseer/config   # jellyseer DB + settings.json
  - /opt/docker/headscale/config   # headscale DB + all private keys
  - /opt/docker/immich/config      # immich config (DB handled via pg_dump)
  - /opt/docker/zitadel/config     # zitadel YAML (DB handled via pg_dump)

restic_pre_commands:
  # existing Postgres dumps
  - "mkdir -p /opt/restic/db-dumps/zitadel && docker exec zitadel-postgres pg_dumpall -U postgres > /opt/restic/db-dumps/zitadel/dump.sql"
  - "mkdir -p /opt/restic/db-dumps/immich && docker exec immich-postgres pg_dumpall -U postgres > /opt/restic/db-dumps/immich/dump.sql"
  # SQLite hot-backups (consistent path, overwritten each run)
  - "mkdir -p /opt/restic/db-dumps/jellyfin && sqlite3 /opt/docker/jellyfin/config/data/data/jellyfin.db    '.backup /opt/restic/db-dumps/jellyfin/jellyfin.db'"
  - "mkdir -p /opt/restic/db-dumps/jellyfin && sqlite3 /opt/docker/jellyfin/config/data/data/users.db       '.backup /opt/restic/db-dumps/jellyfin/users.db'"
  - "mkdir -p /opt/restic/db-dumps/jellyfin && sqlite3 /opt/docker/jellyfin/config/data/data/activitylog.db '.backup /opt/restic/db-dumps/jellyfin/activitylog.db'"
  - "mkdir -p /opt/restic/db-dumps/sonarr    && sqlite3 /opt/docker/sonarr/config/sonarr.db        '.backup /opt/restic/db-dumps/sonarr/sonarr.db'"
  - "mkdir -p /opt/restic/db-dumps/radarr    && sqlite3 /opt/docker/radarr/radarr.db               '.backup /opt/restic/db-dumps/radarr/radarr.db'"
  - "mkdir -p /opt/restic/db-dumps/bazarr    && sqlite3 /opt/docker/bazarr/config/db/bazarr.db     '.backup /opt/restic/db-dumps/bazarr/bazarr.db'"
  - "mkdir -p /opt/restic/db-dumps/bitwarden && sqlite3 /opt/docker/bitwarden/db.sqlite3           '.backup /opt/restic/db-dumps/bitwarden/db.sqlite3'"
  - "mkdir -p /opt/restic/db-dumps/headscale && sqlite3 /opt/docker/headscale/config/db.sqlite     '.backup /opt/restic/db-dumps/headscale/db.sqlite'"
  - "mkdir -p /opt/restic/db-dumps/jellyseer && sqlite3 /opt/docker/jellyseer/config/db/db.sqlite3 '.backup /opt/restic/db-dumps/jellyseer/db.sqlite3'"

restic_post_commands:
  - "rm -rf /opt/restic/db-dumps"            # existing — unchanged
```

Plus `restic_directories`:

```yaml
restic_directories:
  - zfs_pool: saru/noah       # existing
    directory: ""
  - zfs_pool: saru/media      # existing
    directory: photos
  - zfs_pool: saru/scans      # NEW — confirmed as dataset (998 MB)
    directory: ""
  - zfs_pool: saru/amos       # NEW — family data (1.7 GB)
    directory: ""
  # saru/syncthing — dropped, dataset to be destroyed pre-port (unused)
```

## Open questions from this research

1. **~~Zitadel masterkey location~~** — resolved: passed as `--masterkey`
   CLI arg at container start. Value is in
   `ansible-nas/inventories/saru/group_vars/nas/vault.yml`. For the port:
   create `clan.core.vars.generators.zitadel-masterkey` with
   `persist = true`, seed with the current value one-off, then the
   NixOS-hosted Zitadel uses the generator's output.
2. **`saru/amos`** — back up (1.7 GB family data) or skip?
3. **`saru/syncthing`** — back up (currently 196 KB, empty) or skip?
4. **Three Syncthing instances** — `syncthing`, `syncthing-noah`,
   `syncthing-scans`. Which are actually active, which are stale? Action:
   `docker ps` vs `docker ps -a` comparison + check each instance's
   config.xml.

## NixOS-side exclude patterns (for Phase 9 clan-core restic)

When the clan-core restic service goes live on saru/fenix/aiur, each
service's `clan.core.state.<name>.folders` should use these excludes to
keep snapshots clean:

```nix
exclude = [
  # Service-side auto-backups (we are the backup)
  "SQLiteBackups"    # jellyfin plugin
  "Backups"          # sonarr, radarr
  "backup"           # bazarr (lowercase)
  # SQLite sidecar files (transient; would produce torn reads anyway)
  "*.db-wal"
  "*.db-shm"
  "*.db-journal"
  # Generic bak suffix + bitwarden-style timestamped manual backups
  "*.bak"
  "db_*.sqlite3"
  # Service log databases (regeneratable, noisy)
  "logs.db"
];
```

Ansible-nas's current expanded-backup set does NOT have these excludes —
the current-gen restic snapshots include stale service-side backups.
Acceptable transiently; NixOS restic must apply the excludes from day one.

## Migration impact (how this matrix feeds the port)

For each service-port phase in PORT-PLAN.md, restore becomes:

1. Stop NixOS service (or it hasn't started yet).
2. `restic restore latest --tag pre-port-saru --include /opt/docker/<svc>
   --target /tmp/restore`.
3. `rsync` or `mv` the files from `/tmp/restore/opt/docker/<svc>/` into the
   NixOS service's state directory (per table above).
4. If we have a `sqlite3 .backup` for this service:
   `restic restore latest --include /opt/restic/db-dumps/<svc> --target
   /tmp/restore` and overwrite the raw DB with the consistent dump.
5. `chown -R <svc>:<svc>` the state dir.
6. Start service.

All services we care about keep state under `/opt/docker/<svc>` — no
anonymous volumes, no surprise paths outside. Confirmed.

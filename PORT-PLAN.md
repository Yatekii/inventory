# Port `saru` (ansible-nas) → NixOS / Clan

Plan for migrating `~/repos/ansible-nas` (Ubuntu 20.04 + Docker + Traefik, deployed
to host `saru` at 192.168.178.76) into this repo's Clan/Nix layout.

## Goals & constraints

- **Preserve ZFS data**. The host already has the `saru` pool (2×4TB Seagate
  mirror + 2×14TB WD mirror, healthy) with irreplaceable data. The port must
  import this pool on the new NixOS install without reformatting the data
  disks.
- **Restic-as-migration-transport**. State on the to-be-wiped ext4 root
  (`/opt/docker/*`, `/var/lib/docker/volumes`, `/etc/ssh`, `/home/yatekii`,
  pg_dumps) is captured in a final pre-port restic snapshot tagged
  `pre-port-saru` pushed to the existing Hetzner StorageBox repo. Each
  service-port phase restores its slice from that snapshot into the new
  NixOS path — same backup repo, same credentials, no parallel mechanism.
- **Minimal user-visible downtime** for the services the household actively
  depends on (Jellyfin, Syncthing, Vaultwarden, Samba shares, Immich).
- **Declarative identity**. Replace the Docker-based Zitadel with Kanidm on
  fenix, provisioned through `services.kanidm.provision`. Passkey-first
  (TouchID/FaceID) with password+TOTP fallback and a YubiKey break-glass.
- **Use nixos-unstable**, always. Accept the small rough-edge tax in exchange
  for upstream parity.
- **Follow existing patterns in this repo**:
  - Clan services under [modules/clan/](modules/clan/) imported from a machine's
    configuration.
  - Caddy (not Traefik) as reverse proxy, each service self-registers a
    `virtualHost` — see [modules/clan/mealie.nix](modules/clan/mealie.nix).
  - Secrets via `clan.core.vars.generators` — see the `mealie-oidc` generator
    in [modules/clan/mealie.nix](modules/clan/mealie.nix) and the DKIM
    generators in [modules/clan/stalwart.nix](modules/clan/stalwart.nix).
  - Per-service backup via `clan.core.state.<name>` contracts, driven by
    clan-core's `inventory.services.restic` service (scaffolded in
    [modules/flake/parts/clan.module.nix](modules/flake/parts/clan.module.nix),
    currently commented — Phase 9 activates).
  - Deploy via `clan machines update <host>`.
- **Prefer native NixOS modules over containers**. Fall back to OCI only
  when no mature module exists.
- **No AI attribution in commits** (per [CLAUDE.md](CLAUDE.md)).

## Non-goals

- Not porting disabled ansible-nas roles (Conduit, Cloudreve, Calibre,
  Guacamole, Homeassistant, Homebridge, Lidarr, Mylar, Netbootxyz, Prowlarr,
  Thelounge).
- Not porting NFS — Samba only for LAN file sharing.
- Not porting the ansible-nas WireGuard client VPN (6 phone/laptop peers) —
  it was not in active use. Phone/guest access moves to Headscale.
- Not porting Flood — not needed; re-evaluate later if missed.
- Not porting Watchtower. Image updates happen via flake bumps + redeploy,
  for both native modules and OCI containers.
- Not porting Postfix. `msmtp` replaces it for Fastmail relay.
- Not changing `saru`'s role — single-host NAS on home LAN.
- Not changing backup target — Hetzner StorageBox stays.
- Not switching DNS registrars or providers — Namecheap stays.
- Not keeping Zitadel long-term. It runs on saru as OCI during the port,
  then is decommissioned once all OIDC clients have moved to Kanidm.

## Resolved decisions

| Topic | Decision |
|---|---|
| Install strategy | **nixos-anywhere** from laptop over SSH. Wipes `nvme0n1` only; `sda`–`sdd` (the ZFS pool) are never declared in disko and are untouched. |
| NVMe by-id | `nvme-SAMSUNG_MZVL2256HCHQ-00B00_S674NF0R106474`. ZFS encryption is `off` — nothing to preserve. |
| State preservation | Final pre-port restic snapshot on the existing ansible-nas repo with tag `pre-port-saru`, expanded to include `/opt/docker/*`, `/var/lib/docker/volumes` (~75 anonymous volumes, hex-named), `/etc/ssh`, `/home/yatekii`, `/root`, and pg_dumps for zitadel + immich. Plus a one-off `dd` of `nvme0n1` to the ZFS pool for total-disaster rollback. Pool is `zpool export`ed as the last step before nixos-anywhere. |
| Caddy ACME | Stay on Namecheap. `pkgs.caddy.withPlugins` with the `caddy-dns/namecheap` plugin. One-time Namecheap dashboard step to whitelist saru's public IP. |
| Vaultwarden domain | **Rename** `bitwarden.huesser.dev` → `vaultwarden.huesser.dev` during migration. Clients re-enter the server URL once. |
| Vaultwarden version | Pin ansible-nas Docker image to the version in nixpkgs-unstable for a cycle before cutover, so SQLite schema aligns. |
| Identity provider | **Kanidm on fenix** (not saru — fenix's Hetzner uplink is more reliable for the thing everything else authenticates against). Provisioned via `services.kanidm.provision` with `autoRemove = true`. End-user self-service UI at `/ui/`; admin via CLI + Nix. |
| Zitadel | Ported to saru as OCI container in Phase 6 to keep mealie/stalwart working mid-port. Decommissioned in a later milestone once OIDC clients have migrated to Kanidm. |
| Clan interconnect | **Swap zerotier → clan-core `wireguard` clanService** (Phase 1.5, touches aiur + fenix + saru together). Decision: user prefers WireGuard; clan-core ships a wireguard clanService. |
| Headscale | Stays on saru. Separate overlay from clan interconnect — handles non-clan-managed clients (phones, iPads, MacBook, guests). Clan hosts can optionally join the Tailnet later; deferred. |
| Syncthing | Use clan-core's `syncthing` clanService — declarative folder config, automatic device pairing between clan hosts. Replaces hand-rolled `services.syncthing`. |
| Immich | Native `services.immich` on nixos-unstable (currently 2.7.5, upstream parity). Module bundles Postgres+vectorchord+ML. Keep compose in the `pre-port-saru` restic snapshot for 30-day rollback if native bites. |
| Monitoring | Deferred to a later milestone. Basic alerting (ZED + smartd + systemd OnFailure → email via msmtp) lands in Phase 9.5. Future full monitoring must scrape all three hosts. |
| Restic | Activate clan-core's `inventory.services.restic` (already scaffolded, never turned on). Each service declares `clan.core.state.<name>` with folders + pre/post hooks. Fallback to per-machine `services.restic.backups` if clan's service is janky. |

## Service disposition matrix

| Service (ansible-nas) | Target on NixOS | Notes |
|---|---|---|
| Samba | `services.samba` native | Re-declare 4 shares (amos/media/scans/noah). `@scanner` group write on `scans`. |
| NFS | **Drop** | Not needed. |
| Docker host | `virtualisation.docker` | Kept for the remaining OCI services (jellyseer, zitadel). |
| Traefik | **Drop** → Caddy | Namecheap DNS-01 via `caddy.withPlugins`. |
| Jellyfin | `services.jellyfin` native | Config restored from restic. OIDC via Kanidm. |
| Transmission | `services.transmission` native | Admin auth + watch folder `/saru/media/torrents`. |
| Flood | **Drop** | Not carrying forward. |
| Radarr | `services.radarr` native | **Service state is SQLite + XML — not declaratively configurable.** Internal config (indexers, quality profiles, download client, root folders) migrates via restic restore of `/opt/docker/radarr` into `/var/lib/radarr`, chown'd to the service user. Recyclarr is a *partial* YAML layer for quality profiles — defer as optional. |
| Sonarr | `services.sonarr` native | Same pattern as Radarr. |
| Bazarr | `services.bazarr` native | Same. |
| Jackett | `services.jackett` native | Same. Prowlarr swap is backlog. |
| Vaultwarden | `services.vaultwarden` native | Activate the scaffolding in [modules/clan/vaultwarden.nix](modules/clan/vaultwarden.nix). Data (`db.sqlite3*`, `attachments/`, `sends/`, `rsa_key*`) restored from restic. Domain **renamed** to `vaultwarden.huesser.dev`. |
| Jellyseer (Overseerr) | OCI container | No native module. |
| Syncthing | clan-core `syncthing` clanService | Declarative folder/device config; replaces the hand-rolled ansible-nas Docker setup. |
| WireGuard (client VPN for 6 phones/laptops) | **Drop** | Not used. Guest/mobile access moves to Headscale. |
| Zerotier (clan interconnect, current) | **Replace** with clan-core `wireguard` clanService | Phase 1.5 swap affecting aiur + fenix + saru. |
| Zitadel | OCI container, temporary | Phase 6: ported as-is to keep mealie/stalwart OIDC working during migration. Decommissioned after all clients have moved to Kanidm (backlog milestone). |
| Kanidm (new, replaces Zitadel long-term) | `services.kanidm` + `services.kanidm.provision` | Deployed to **fenix**, not saru. Hosts the OIDC endpoint. Online backup enabled; picked up by restic. |
| Immich | `services.immich` native | Bundles Postgres+vectorchord+ML. Data restored from restic (container volumes + pg_dump). |
| Headscale | `services.headscale` native on saru | Separate from clan interconnect. Handles non-clan-managed clients (phones, iPads, MacBook, guests). OIDC via Kanidm. |
| Restic | clan-core `inventory.services.restic` | Activate the commented scaffolding in [modules/flake/parts/clan.module.nix](modules/flake/parts/clan.module.nix). Pre-port snapshot (Phase 0) proves the StorageBox repo before NixOS takes over writes. |
| Netdata | `services.netdata` native | Lightweight live-view; not a monitoring replacement. |
| Watchtower | **Drop** (all containers) | Image updates via flake bumps + redeploy. Same workflow for native modules and OCI. |
| Unattended-upgrades | **Drop** | N/A on NixOS. |
| Stats (InfluxDB/Telegraf/Grafana) | **Drop for now** | Replaced by Phase 9.5 basic alerting. Full monitoring = separate milestone. |
| msmtp relay (Fastmail) | `programs.msmtp` native | Sendmail shim for ZED/smartd/systemd. Pulled forward to Phase 2. |
| MOTD customization | `users.motd` / `programs.motd` | Trivial. |
| ZED (ansible-nas WIP security tool, unrelated to ZFS Event Daemon) | **Skip** | Never deployed. |

## Phased rollout

Each phase ends with saru still booting and critical data intact.

### Phase 0 — Pre-port capture (no machine changes)

**Strategy**: the expanded ansible-nas nightly restic config (see
[backup-matrix.md](backup-matrix.md) and the diff applied to
`ansible-nas/inventories/saru/group_vars/nas/vars.yml`) covers every
service's state going forward. Phase 0 just ensures the **last nightly run
before cutover** is our authoritative source, plus disaster-rollback and
pool export.

**Preparation (days before cutover)**:

1. Deploy the expanded ansible-nas restic config (`ansible-playbook nas.yml`).
   Verify the first nightly run succeeds, listing all the new paths and
   per-service SQLite / pg dumps in the output.
2. One-time cleanup of service-side auto-backups (they're redundant now
   that we're the authoritative backup):
   - Jellyfin: Admin Dashboard → Scheduled Tasks → disable "Backup
     Database". `rm -rf /opt/docker/jellyfin/config/data/data/SQLiteBackups/*`
     (reclaims 9.3 GB).
   - Sonarr/Radarr: Settings → General → Backup → retention 1 (or
     disable). `rm -rf /opt/docker/{sonarr/config,radarr}/Backups/*`.
   - Bazarr: same. `rm -rf /opt/docker/bazarr/config/backup/*`.
   - `rm -f /opt/docker/bitwarden/db_20250625_192606.sqlite3` (stray
     manual backup).
3. ZFS cleanup: `zfs destroy saru/syncthing` (unused dataset).
4. Enumerate secrets that need clan.core.vars generators (see
   [backup-matrix.md](backup-matrix.md) per service). Most relevant:
   - Zitadel masterkey — currently in ansible-vault, passed as `--masterkey`
     CLI arg. Move to `clan.core.vars.generators.zitadel-masterkey` in
     NixOS config, seed with the existing value.
   - Transmission admin password, Namecheap API key, Fastmail SMTP
     credential, Hetzner StorageBox SSH key — same pattern.

**Day of cutover (on saru)**:

1. Confirm the last nightly restic run covered everything and is
   < 24 h old.
2. Stop all containers: `docker stop $(docker ps -q)`.
3. Run one final restic snapshot on top of the nightly (ensures
   zero-lag) using the existing ansible-nas `restic.sh` script.
4. Disaster-rollback image for the boot disk:
   ```
   zfs create saru/migration
   dd if=/dev/nvme0n1 of=/saru/migration/boot-disk-pre-port.img bs=4M status=progress
   ```
5. Export the ZFS pool: `sudo zpool export saru`.

**Exit**: the StorageBox has a restic snapshot < 1 h old; boot-disk image
on ZFS; pool exported; `machines/saru/NOTES.md` in the worktree branch
with the enumerated state (Traefik route list, service port list). Ready
for nixos-anywhere.

### Phase 1 — Machine skeleton + nixos-anywhere install

- [machines/saru/configuration.nix](machines/saru/configuration.nix):
  imports `shared.nix`, `nix.nix`, `ssh-keys.nix`, `helix.nix`;
  `boot.supportedFilesystems = [ "zfs" ]`; `boot.zfs.extraPools = [ "saru" ]`;
  `networking.hostId = "..."` (required for ZFS); `time.timeZone =
  "Europe/Zurich"`.
- [machines/saru/disko.nix](machines/saru/disko.nix): declares **only** the
  NVMe (by-id above). ESP (500M vfat) + root (ext4, 100%). Data pool disks
  not mentioned; disko ignores them.
- Register saru in [modules/flake/parts/clan.module.nix](modules/flake/parts/clan.module.nix)
  (sshd, user-root, user-yatekii, trusted-nix-caches roles).
- Run `nixos-anywhere` from laptop over SSH to the live Ubuntu host (after
  Phase 0's export). First NixOS boot imports the `saru` pool cleanly via
  `extraPools` — no manual `-f` because Phase 0 exported it.

**Exit**: `ssh saru uptime` works; `zfs list -t snapshot | head` shows
existing snapshots; `restic snapshots --tag pre-port-saru` accessible from
saru; no services running yet.

### Phase 1.5 — Clan interconnect: zerotier → wireguard

Single disruptive mesh migration so we don't do it twice.

- Add `inventory.services.wireguard` instance in
  [modules/flake/parts/clan.module.nix](modules/flake/parts/clan.module.nix)
  with aiur as controller role, fenix + saru as peer roles (following the
  clan-core wireguard service contract).
- Remove the zerotier instance (`clan.core.networking.zerotier.controller.enable`
  overrides etc.).
- Deploy in order: aiur → fenix → saru. Validate connectivity after each.
- Keep the zerotier network-id in `machines/saru/NOTES.md` for 30 days in
  case rollback is needed.

**Exit**: `ping` between all three hosts works over the clan wireguard mesh;
zerotier interfaces gone.

### Phase 2 — LAN services + msmtp relay

- `modules/clan/samba.nix` — 4 shares (amos/media/scans/noah), map-to-guest
  for the public shares, `@scanner` group write on `scans`. Declare the
  `scanner` group. `/etc/ssh/ssh_host_*` restored from restic first so
  clients don't get a host-key change warning.
- Firewall: LAN-only for Samba (445/TCP, 139/TCP, 137/UDP, 138/UDP).
- `modules/clan/msmtp.nix` — `programs.msmtp` pointed at
  `smtp.fastmail.com:465` (implicit TLS). Credential via
  `clan.core.vars.generators.fastmail-smtp` (password prompt, persisted).
  Sets up `programs.msmtp.setSendmail = true` so `/run/wrappers/bin/sendmail`
  works for ZED/smartd/systemd.

**Exit**: SMB clients reconnect to saru; `echo body | mail -s test
noah@huesser.dev` delivers.

### Phase 2.5 — Kanidm on fenix + migrate Zitadel OIDC clients

Precondition for later saru phases so new services OIDC straight to Kanidm
from day one.

- `modules/clan/kanidm.nix` — `services.kanidm` server + provision block
  with groups (`mealie_users`, `stalwart_users`, future `immich_users`,
  `jellyfin_users`, `headscale_users`), persons (yatekii, amos), OAuth2
  systems (mealie, stalwart). Follows CLAUDE.md conventions
  (`overwriteMembers = false` for built-in groups; underscore names).
- `modules/clan/individuals.nix` — person definitions per CLAUDE.md pattern.
- Add to fenix's `imports`; `clan machines update fenix`.
- Recovery: `kanidmd recover_account idm_admin` on fenix once.
- Enroll yatekii with TouchID passkey (via `/ui/`) + password + TOTP backup.
  YubiKey as break-glass. Repeat for amos.
- Migrate mealie OIDC from Zitadel to Kanidm: rewrite `mealie-oidc` generator,
  redeploy, verify login.
- Migrate stalwart OIDC: same pattern.
- Enable Kanidm's `online_backup`; add to fenix's `clan.core.state` so
  Phase 9 picks it up.

**Exit**: mealie + stalwart authenticate against Kanidm; Zitadel (on saru)
has no active clients anymore.

### Phase 3 — Caddy + DNS-01 + Jellyfin

- Extend the caddy module with `pkgs.caddy.withPlugins` (Namecheap plugin).
  Credential via `clan.core.vars.generators.namecheap-dns-api`.
- Port-forward 80/443 to saru (was Traefik; same ports).
- First migrated app: **Jellyfin** (`services.jellyfin` + Caddy virtualHost,
  OIDC via Kanidm). Restore `/opt/docker/jellyfin/config` from restic into
  `/var/lib/jellyfin`.

**Exit**: `jellyfin.huesser.dev` resolves to saru, serves via Caddy with a
valid cert; OIDC login via Kanidm works; media library visible.

### Phase 4 — `*arr` stack + Transmission + Jackett

- Native modules for Radarr, Sonarr, Bazarr, Jackett, Transmission.
- Data migration per service:
  ```
  restic restore latest --tag pre-port-saru \
    --include /opt/docker/sonarr --target /tmp/restore
  mv /tmp/restore/opt/docker/sonarr/* /var/lib/sonarr/
  chown -R sonarr:sonarr /var/lib/sonarr
  systemctl start sonarr
  ```
  (Analogously for radarr/bazarr/jackett/transmission.)
- Caddy virtualHosts per service; basic-auth for transmission admin
  (preserve current credential).

**Exit**: existing library visible; downloads resume; indexer list intact.

### Phase 5 — Vaultwarden

- Uncomment [modules/clan/vaultwarden.nix](modules/clan/vaultwarden.nix),
  change `vaultwarden-domain` to `vaultwarden.huesser.dev`, deploy to saru.
- `restic restore` of `/opt/docker/bitwarden/data/{db.sqlite3*,attachments,
  sends,rsa_key*}` into `/var/lib/vaultwarden/`, chown to
  `vaultwarden:vaultwarden`.
- Port SMTP (password-reset emails) into the module's `config` block, using
  msmtp (not a separate SMTP account).
- `clan.core.state.vaultwarden` annotation enables online SQLite backup for
  Phase 9.
- DNS flip + re-enter server URL in clients (one-time UX cost).
- Verify login from browser + mobile before deleting the old restic-restore
  scratch dir.

**Exit**: all clients authenticate on the new domain; no data loss.

### Phase 6 — Immich (native) + Zitadel (OCI, temporary)

- `modules/clan/immich.nix`: `services.immich` native. Bundles Postgres
  (vectorchord extension) + Redis + ML. OIDC via Kanidm. Photos at
  `/saru/media/photos` (already on ZFS — no data move). Stop the compose
  stack, pg_dump, import into the native module's Postgres.
- `modules/clan/zitadel.nix`: single Zitadel container + Postgres as OCI,
  restored from restic. Marked explicitly as **temporary** with a
  `# TODO: decommission` comment.
- `clan.core.state.{immich,zitadel}` with `pg_dumpall` pre-hooks for Phase 9.

**Exit**: Immich photo library intact; Zitadel runs but has no active
clients (mealie/stalwart migrated in Phase 2.5); ready to decommission when
nothing depends on it.

### Phase 7 — Headscale (guest/mobile plane)

- `modules/clan/headscale.nix`: `services.headscale` on saru, admin API via
  Caddy, OIDC via Kanidm.
- Re-register the Tailscale clients (phones, iPads, Mac) — one-time
  onboarding.
- No ansible-nas WireGuard — dropped.

**Exit**: Tailnet reachable; Tailscale clients join and can resolve `saru`,
`fenix`, `aiur` (only if those hosts also join — deferred decision).

### Phase 8 — Syncthing + Jellyseer + Netdata

- Syncthing via **clan-core `syncthing` clanService** — declarative folders
  (`noah-docs`, `scans`), clan hosts auto-pair. Restore prior state from
  restic (`/opt/docker/syncthing` contains the folder IDs to preserve).
- Jellyseer as OCI container.
- Netdata native (local-only web UI).

**Exit**: Syncthing re-identifies existing folders by ID; Jellyseer points
at Sonarr/Radarr.

### Phase 9 — Backups (activate clan-core restic)

- Uncomment the `inventory.services.restic.clan-backup` block in
  [modules/flake/parts/clan.module.nix](modules/flake/parts/clan.module.nix).
- Roles: `client` on saru, fenix, aiur. `externalTarget` = Hetzner
  StorageBox via rclone (creds in `clan.core.vars`).
- `clan.core.state.<name>` contracts on each service contribute folders +
  pre/post hooks:
  - vaultwarden: online SQLite backup.
  - immich + zitadel: `pg_dumpall` pre-hook.
  - kanidm: `online_backup` cron.
  - saru ZFS data: snapshot-and-mount pre-hook for `saru/noah` +
    `saru/media/photos`.
- Systemd timer nightly.
- **Manually verify** one full restore (e.g., vaultwarden SQLite) to a
  scratch dir before declaring Phase 9 done.
- Fallback if clan's service is janky: per-machine `services.restic.backups`.

**Exit**: first nightly snapshot succeeds across all three hosts;
inventory matches what was on StorageBox pre-port.

### Phase 9.5 — Basic alerting

All alerts go out through msmtp (Phase 2) → Fastmail → `noah@huesser.dev`.

- `services.zfs.zed` on saru (*ZFS Event Daemon*, ships with OpenZFS — not
  related to the ansible-nas "ZED security tool" row): `ZED_EMAIL_ADDR`,
  `ZED_EMAIL_PROG = "${pkgs.mailutils}/bin/mail"`. Alerts on pool degraded,
  faulted, scrub error, resilver complete.
- `services.smartd` on saru with mail alerts for disk SMART errors.
- Systemd `OnFailure=status-email@%n.service` template on all three hosts,
  unit defined once in `modules/clan/alerts.nix`. Wired into critical
  services (jellyfin, vaultwarden, immich, kanidm, restic timers).
- Test by forcing a failure on a non-critical unit.

**Exit**: forced failures produce email within ~1 min.

### Phase 10 — Cleanup

- MOTD customization.
- Archive `~/repos/ansible-nas` (final commit on its branch, stop deploying).
- After 30 days of stability: delete `/saru/migration/boot-disk-pre-port.img`
  and prune the `pre-port-saru` restic snapshot.

### Deferred milestones

- **Zitadel decommission** — once no OIDC clients point at it, `pg_dumpall`
  to cold archive, remove the module.
- **Clan hosts join Headscale Tailnet** — if "reach saru from phone without
  LAN" becomes a real pain point.
- **Full monitoring** — Prometheus + Grafana on saru, `node_exporter` on
  all three hosts, scrape across. Replaces InfluxDB/Telegraf.
- **Prowlarr swap** — replaces Jackett; auto-syncs indexers into Sonarr/Radarr.
- **Recyclarr** — partial YAML-declarative layer for *arr quality profiles.
- **ZFS send-based offsite backup** — alternative/complement to restic.

## Risks & mitigations

- **Losing ZFS pool data**. Mitigation: pool disks never named in disko;
  nixos-anywhere physically cannot touch them. Phase 0 exports cleanly so
  no `-f` needed on first import.
- **Losing `/opt/docker` state**. Mitigation: `pre-port-saru` restic snapshot
  + boot-disk `dd` image. Each service-port phase restores explicitly.
- **Zitadel DB restore fails on new host**. Mitigation: test `pg_dumpall` →
  `psql` round-trip against a staging VM before the real cutover. Keep the
  snapshot for 30+ days.
- **Kanidm OIDC cutover breaks mealie/stalwart login**. Mitigation: Phase
  2.5 migrates one client at a time; both Zitadel and Kanidm OIDC endpoints
  stay up during the switch.
- **Clan interconnect swap breaks aiur/fenix**. Mitigation: Phase 1.5 is
  a single deliberate phase — deploy aiur (controller) first, validate
  reachability, then fenix, then saru. Keep zerotier network-id for 30 days
  for rollback.
- **Caddy + Namecheap plugin drift**. Mitigation: pin plugin version;
  Namecheap API whitelist only saru's public IP.
- **Immich native module quirks on unstable**. Mitigation: keep the compose
  stack in the restic snapshot; if ML breaks, fall back temporarily.
- **Clan restic service untested**. Mitigation: prove round-trip on aiur
  first (smallest blast radius), then fenix, then saru.
- **No out-of-band access to saru during install**. Mitigation: dry-run the
  nixos-anywhere disko config against a VM with matching layout first. Boot-
  disk image on ZFS as absolute last resort.

## Next action

**Phase 0 first — prove the backup substrate works before any NixOS code.**

1. Commit the applied vars.yml diff in the ansible-nas repo.
2. `ansible-playbook nas.yml --tags restic` against saru.
3. Manually trigger `/opt/restic/backup.sh` on saru; watch for errors on
   any new path or SQLite `.backup` pre-hook.
4. `restic snapshots` on the StorageBox repo → confirm new paths present.
5. Smoke-test a restore of a single service's dump to a tmp dir; verify
   with a light query (e.g., sonarr `select count(*) from Series`).
6. Deploy the service-side auto-backup reductions and the ZFS cleanup
   (`zfs destroy saru/syncthing`).

**Only after all of the above succeeds**, write Phase 1 files:

- [machines/saru/configuration.nix](machines/saru/configuration.nix)
- [machines/saru/disko.nix](machines/saru/disko.nix)
- Register saru in [modules/flake/parts/clan.module.nix](modules/flake/parts/clan.module.nix)

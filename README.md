# Yatekiis device inventory

This repo will hold the complete configuration of all of yatekii's devices.

## Services

| Service                                     | Host        | URL                                | GitHub                                                            |
| ------------------------------------------- | ----------- | ---------------------------------- | ----------------------------------------------------------------- |
| [Stalwart](https://stalw.art)               | fenix       | mail.huesser.dev, auth.huesser.dev | [stalwartlabs/stalwart](https://github.com/stalwartlabs/stalwart) |
| [Caddy](https://caddyserver.com)            | aiur, fenix | -                                  | [caddyserver/caddy](https://github.com/caddyserver/caddy)         |
| [Conduwuit](https://conduwuit.puppyirl.gay) | aiur        | -                                  | [girlbossceo/conduwuit](https://github.com/girlbossceo/conduwuit) |
| [Zerotier](https://zerotier.com)            | aiur        | -                                  | [zerotier/ZeroTierOne](https://github.com/zerotier/ZeroTierOne)   |
| [Mealie](https://mealie.io)                 | aiur        | -                                  | [mealie-recipes/mealie](https://github.com/mealie-recipes/mealie) |
| [Syncthing](https://syncthing.net)          | auraya      | -                                  | [syncthing/syncthing](https://github.com/syncthing/syncthing)     |

## Setting up this repository on a new host

Run `./install` to install nix and provision the host initially to bring up the entire user environment.

## Provisioning devices

### Darwin

## Design

### Inventory

The repository uses clan, flake-parts, nix-darwin and home-manager for module management.

Optimally we follow the dendritic pattern. Unfortunately that proves very difficult with how clan calls nix-darwin bypassing flake-parts.

That's why we use the flake-parts module system for general flake utils rather than host config. Everything that is _user specific_ config should be in a home-manager module in `modules/home`. If it is specific to a singular user, use `modules/home/<user>`. Everything that is a clan service should use `modules/clan` for modules. Everything that is darwin specific should be in `modules/darwin`.

## Hosts

### auraya

**Platform:** macOS (aarch64-darwin)  
**Type:** Personal MacBook workstation

The primary development machine running nix-darwin with home-manager for user environment management.

**Services:**

- Syncthing (peer sync with mobile devices)
- Declarative Homebrew management

**Setup:**

```bash
./install  # Bootstrap nix and apply configuration
nix run .#apply -- auraya  # Apply configuration updates
```

### aiur

**Platform:** NixOS (x86_64-linux)  
**Type:** Hetzner Cloud VPS  
**IP:** 142.132.172.209

Primary server for communication and collaboration services.

**Services:**

- Caddy (reverse proxy with automatic HTTPS)
- Conduwuit (Matrix homeserver) - partially configured
- Zerotier controller (mesh VPN)
- Mealie (recipe manager)

**Ports:** 80, 443, 8448 (Matrix federation)

**Setup:**

```bash
nix run .#apply-tf  # Provision infrastructure
clan machines update aiur  # Deploy NixOS configuration
```

### fenix

**Platform:** NixOS (aarch64-linux)  
**Type:** Hetzner Cloud VPS  
**IP:** Dynamic (see machines/machines.json)

Secondary server for personal productivity services.

**Services:**

- Caddy (reverse proxy with automatic HTTPS)
- Stalwart (email server + identity provider) at mail.huesser.dev and auth.huesser.dev

**Setup:**

```bash
nix run .#apply-tf  # Provision infrastructure
clan machines update fenix  # Deploy NixOS configuration
```

## Authentication & Email (Stalwart)

Stalwart Mail Server provides both email services and acts as an OIDC identity provider. It is hosted on fenix with the web interface at `mail.huesser.dev` and OIDC endpoints at `auth.huesser.dev`.

### Managed Users

Users are defined declaratively in `modules/clan/persons.nix`:

| User | Email            | Role  |
| ---- | ---------------- | ----- |
| noah | noah@huesser.dev | admin |

### Adding a New User

1. Edit `modules/clan/persons.nix`
2. Add to `persons`:
   ```nix
   persons = {
     newuser = {
       displayName = "New User";
       mailAddresses = [ "newuser@huesser.dev" ];
       admin = false;  # or true for admin access
     };
   };
   ```
3. Run `clan machines update fenix`

**Note:** User changes require a Stalwart restart (happens automatically during deploy) because the in-memory directory is loaded at startup.

### Secrets

User passwords are auto-generated and stored in clan vars:

| Secret                          | Purpose                      |
| ------------------------------- | ---------------------------- |
| `stalwart-admin-password`       | Fallback admin account       |
| `stalwart-user-<name>-password` | Login password for each user |

To retrieve a user's password:

```bash
sops -d vars/per-machine/fenix/stalwart-user-noah-password/password/secret
```

### OIDC Endpoints

Stalwart exposes OIDC endpoints at `auth.huesser.dev` for use by other services:

| Endpoint      | URL                                                       |
| ------------- | --------------------------------------------------------- |
| Discovery     | https://auth.huesser.dev/.well-known/openid-configuration |
| Authorization | https://mail.huesser.dev/authorize/code                   |
| Token         | https://mail.huesser.dev/auth/token                       |
| UserInfo      | https://mail.huesser.dev/auth/userinfo                    |
| JWKS          | https://mail.huesser.dev/auth/jwks.json                   |

### Email Access

- **Web Interface:** https://mail.huesser.dev
- **IMAP:** mail.huesser.dev:993 (TLS)
- **SMTP Submission:** mail.huesser.dev:465 (TLS) or :587 (STARTTLS)

### Known Limitations

- **Web UI Dashboard:** The dashboard shows 0 users/domains because Stalwart's API doesn't expose full principal data from in-memory directories. Authentication and mail delivery still work correctly.
- **Live Telemetry:** The "Not found" errors on dashboard pages are because Live Tracing/Telemetry is an Enterprise-only feature in Stalwart Community Edition.
- **Outbound Port 25:** Hetzner blocks outbound port 25 by default. A support request must be submitted to unblock it for sending mail to external servers.

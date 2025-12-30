# Yatekiis device inventory

This repo will hold the complete configuration of all of yatekii's devices.

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
- Kanidm (identity provider / SSO) at auth.huesser.dev
- Stalwart (email server) with OIDC authentication via Kanidm

**Setup:**

```bash
nix run .#apply-tf  # Provision infrastructure
clan machines update fenix  # Deploy NixOS configuration
```

## Authentication (Kanidm)

Kanidm provides Single Sign-On (SSO) for all services. It is hosted on fenix at `auth.huesser.dev`.

### Managed Users

Users are defined declaratively in `modules/clan/individuals.nix`:

| User | Email            | Groups                                     |
| ---- | ---------------- | ------------------------------------------ |
| noah | noah@huesser.dev | idm_admins, stalwart_users, stalwart_admin |

### Groups

| Group            | Purpose                                   |
| ---------------- | ----------------------------------------- |
| `idm_admins`     | Built-in Kanidm group for user management |
| `stalwart_users` | Access to mail services                   |
| `stalwart_admin` | Admin access to Stalwart web UI           |

**Note:** Group names use underscores (matching Kanidm's built-in groups), not periods. Periods conflict with Kanidm's SPN format.

### OAuth2/OIDC Applications

| Application | URL              | Description                   |
| ----------- | ---------------- | ----------------------------- |
| Stalwart    | mail.huesser.dev | Email server (IMAP/SMTP/JMAP) |

### Adding a New User

1. Edit `modules/clan/individuals.nix`
2. Add to `individuals`:
   ```nix
   individuals = {
     newuser = {
       displayName = "New User";
       mailAddresses = [ "newuser@huesser.dev" ];
       groups = [ "stalwart_users" ];
     };
   };
   ```
3. Add new groups to `groups` if needed
4. Run `clan machines update fenix`

### Adding a New OAuth2 Application

1. Edit `modules/clan/kanidm.nix`
2. Add to `provision.systems.oauth2`:
   ```nix
   systems.oauth2 = {
     myapp = {
       displayName = "My Application";
       originUrl = "https://myapp.huesser.dev/callback";
       originLanding = "https://myapp.huesser.dev";
       scopeMaps = {
         "myapp.users" = [ "openid" "email" "profile" ];
       };
     };
   };
   ```
3. Create corresponding access group in `individuals.nix`
4. Run `clan machines update fenix`

### Secrets

The following secrets are auto-generated and stored in clan vars:

| Secret                      | Purpose                                                    |
| --------------------------- | ---------------------------------------------------------- |
| `kanidm-idm-admin-password` | Used by provisioning service to set initial user passwords |
| `oidc-stalwart-secret`      | OAuth2 client secret for Stalwart ↔ Kanidm                |
| `oidc-user-<name>-password` | Initial login password for each user                       |

To retrieve a user's initial password:

```bash
cat vars/per-machine/fenix/oidc-user-noah-password/password/secret
```

**Note:** Users in `idm_admins` group can manage other users via the Kanidm web UI at `auth.huesser.dev`.

### Email Authentication

Stalwart uses Kanidm for OIDC authentication. Mail clients that support OAUTHBEARER can authenticate directly. For clients without OAuth support (Thunderbird, Apple Mail), use App Passwords generated in the Stalwart web interface.

**Important:** Users must log in via the web interface at least once before they can receive email, as Kanidm OIDC doesn't provide a way to enumerate users offline.

### Troubleshooting

#### Renaming or removing groups/users

The `kanidm-provision` tool with `autoRemove = true` automatically synchronizes state. When you rename a group (e.g., `foo` → `bar`), the old group is automatically deleted and the new one created. No manual database reset needed.

#### Kanidm provisioning fails with 403 Forbidden

If `kanidm-provision` fails with a 403 error when creating groups (especially `ext_idm_provisioned_entities`), the database was likely created before the `withSecretProvisioning` patches were applied. The solution is to reset the database:

```bash
# On fenix:
sudo systemctl stop kanidm
sudo rm -rf /var/lib/kanidm/kanidm.db
sudo systemctl start kanidm
```

The database will be recreated with proper access control profiles on next startup. User passwords will be re-set automatically (the service queries Kanidm to check if credentials exist).

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is "khala" - a NixOS/Nix flake-based infrastructure repository managing multiple machines using Clan, nix-darwin, home-manager, and Terraform/OpenTofu for Hetzner Cloud provisioning.

## Common Commands

```bash
# Development
nix develop                     # Enter dev shell with clan-cli, tofu, xtask, git
nix fmt                         # Format all files (nixfmt + terraform via treefmt)

# Machine configuration
# IMPORTANT: For NixOS machines (aiur, fenix), ALWAYS use `clan machines update`, NOT `nix run .#apply`!
nix run .#apply -- auraya       # Apply config to auraya (darwin-rebuild switch) - macOS only
clan machines update aiur       # Deploy to aiur (NixOS) - ALWAYS use this for NixOS!
clan machines update fenix      # Deploy to fenix (NixOS) - ALWAYS use this for NixOS!
./install                       # Bootstrap script for new hosts

# Infrastructure (Terraform/OpenTofu) - always use nix run, not vanilla tofu commands
nix run .#apply-tf              # Terraform apply (provision Hetzner resources)
nix run .#destroy-tf            # Terraform destroy

# xtask utilities
xtask derive-machines-json <tofu-binary> <state-file> <output.json>
xtask gather-disk-ids <machines.json>
xtask gather-terraform-files <machines-dir> <terraform-dir>
xtask clean-terraform-files <terraform-dir>
```

## Architecture

### Machine Types

- **auraya**: macOS (aarch64-darwin) - personal MacBook, uses nix-darwin + home-manager + declarative Homebrew
- **aiur**: NixOS Linux (x86_64) - Hetzner server, runs Caddy, Zerotier controller, Matrix/Conduwuit
- **fenix**: NixOS Linux (aarch64) - Hetzner server, runs Vaultwarden, Mealie, Caddy

### Directory Structure

- `machines/<name>/` - Machine-specific configurations (configuration.nix, disko.nix, homebrew.nix)
- `modules/clan/` - Clan service modules for NixOS (caddy, mealie, vaultwarden, shared settings)
- `modules/home/user/<user>/` - Home-manager user configurations
- `modules/darwin/` - Darwin-specific modules (not fully migrated yet)
- `flake/modules/lib/` - Reusable library functions (terraform helpers, xtask wrapper)
- `flake/modules/parts/` - Flake-parts outputs (shells, formatter, apps)
- `terraform/` - OpenTofu infrastructure code for Hetzner Cloud
- `xtask/` - Rust utility for infrastructure tasks
- `vars/` - Clan variable/secret management
- `sops/` - SOPS encryption configuration

### Design Patterns

**Dendritic module pattern** (with limitations due to clan/nix-darwin interaction):

- User-specific config → `modules/home/<user>/`
- Clan services → `modules/clan/`
- Darwin-specific → `modules/darwin/`
- Flake utilities → `flake/modules/`

**Module discovery**: `gatherModules` in `modules/flake/gatherModules.nix` recursively discovers `.nix` files (excluding `_`-prefixed items).

**Terraform workflow**:

1. Machine definitions in `machines/<name>/machine.tf`
2. `gather-terraform-files` copies to `terraform/` with `_` prefix
3. `tofu apply` provisions infrastructure
4. `derive-machines-json` parses state into `machines.json`
5. `gather-disk-ids` SSHs to servers for device IDs
6. `clean-terraform-files` removes temporary files

### Key Dependencies

- `clan-core` - Infrastructure framework (from git.clan.lol)
- `nixpkgs` - nixos-unstable channel
- `nix-darwin` - macOS configuration
- `home-manager` - User environment management
- `flake-parts` - Modular flake organization
- `nix-homebrew` - Declarative Homebrew on macOS
- `opentofu` - Infrastructure provisioning
- `treefmt-nix` - Multi-language formatting

## Kanidm (Identity Provider)

Kanidm is configured in `modules/clan/kanidm.nix` with users defined in `modules/clan/individuals.nix`.

### Important Conventions

- **Group names must use underscores, not periods** (e.g., `stalwart_users` not `stalwart.users`). Periods conflict with Kanidm's SPN format which uses periods for domain components.
- **autoRemove is enabled** - The `kanidm-provision` tool automatically deletes groups/users removed from config.
- **Password detection** - The password-setting service queries Kanidm directly (`kanidm person credential status`) to check if a user has credentials, rather than using marker files.
- **Database reset** - If provisioning fails with 403 on `ext_idm_provisioned_entities`, delete the database (`rm /var/lib/kanidm/kanidm.db*`) and restart the service.

### Built-in Groups and idm_admin

**Critical**: The `idm_admin` account must remain a member of `idm_admins` for provisioning to work. The NixOS kanidm module uses `idm_admin` to run `kanidm-provision`.

- On a fresh Kanidm database, `idm_admin` is automatically a member of `idm_admins`
- If you provision the `idm_admins` group with `overwriteMembers = true` (default), it will **replace** all members, removing `idm_admin` and breaking future provisioning runs
- **Solution**: For built-in groups like `idm_admins`, set `overwriteMembers = false` to append your users instead of replacing. This is implemented in `builtinGroupMembers` in `kanidm.nix`.

### Troubleshooting

If provisioning fails with "accessdenied" when creating groups:

1. The `idm_admin` account was likely removed from `idm_admins`
2. Fix: Delete the database and restart: `systemctl stop kanidm && rm -f /var/lib/kanidm/kanidm.db* && systemctl start kanidm`
3. The fresh database will have `idm_admin` in `idm_admins`, and provisioning will work

To fully reset and reprovision Kanidm:

```bash
# 1. Clear the database and cached tokens
ssh root@fenix "systemctl stop kanidm && rm -f /var/lib/kanidm/kanidm.db* && rm -f ~/.cache/kanidm_tokens"

# 2. Reprovision using clan (ALWAYS use this to verify provisioning works)
nix develop -c clan machines update fenix
```

**Important**: Always use `clan machines update` to test provisioning, not just `systemctl start`. This ensures the full NixOS activation runs, including the kanidm post-start provisioning script.

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
nix run .#apply -- auraya       # Apply config to auraya (darwin-rebuild switch)
nix run .#apply -- aiur         # Apply config to aiur (NixOS rebuild)
nix run .#apply -- fenix        # Apply config to fenix (NixOS rebuild)
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

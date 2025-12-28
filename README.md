# Yatekiis device inventory

This repo will hold the complete configuration of all of yatekii's devices.

## Setting up this repository on a new host

Run `./install` to install nix and provision the host initially to bring up the entire user environment.

## Provisioning devices

### Darwin

## Design

### Inventory

The repository uses clan, flake-parts, nix-dawrin and home-manager for module management.

Optimally we follow the dendritic pattern. Unfortunately that proves very difficult with how clan calls nix-darwin bypassing flake-parts.

That's why we use the flake-parts module system for general flake utils rather than host config. Everything that is _user specific_ config should be in a home-manager module in `modules/home`. If it is specific to a singular user, use `modules/home/<user>`. Everything that is a clan service should use `modules/clan` for modules. Everything that is darwin specific should be in `modules/darwin`.

### Hosts

#### auraya

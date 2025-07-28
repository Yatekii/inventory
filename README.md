# Khala

## Provisioning a new machine

- Add a subdirectory with the machine `<name>` in `/machines`.
- Add a `machine.tf` file if you want a Hetzner node for that machine.
- Run `nix run .#apply` to provision the new Hetzner node.
- Add a `configuration.nix`.
- Run `clan machines update-hardware-config <name>` to generate a `facter.json`.
- Run `clan machines install <name> --target-host root@<ip>` to install NixOS.

## Updating an existing machine

- Run `clan machines update <name>`.

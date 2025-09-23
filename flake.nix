{
  inputs = {
      clan-core.url =
    "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
    # inputs.clan-core.url =
    #   "git+https://git.clan.lol/Yatekii/clan-core?ref=init-restic";
    # inputs.clan-core.url = "path:///Users/yatekii/repos/clan-core";
    nixpkgs.follows = "clan-core/nixpkgs";

    # We use flake-parts to modularaize our flake
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "clan-core/nixpkgs";
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, clan-core, ... }:
    let
      hetzner-offsite-backup-user = "u415891";
      hetzner-offsite-backup-host =
        "${hetzner-offsite-backup-user}.your-storagebox.de";
    in
      flake-parts.lib.mkFlake {
        inherit inputs;
        specialArgs = {
          helpers = import ./flake/helpers {
            inherit inputs;
          };
        };
      } ({self, pkgs, ...}: {
        # See: https://flake.parts/getting-started
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];

        # Import the Clan flake-parts module
        imports = [
          ./flake/parts
          clan-core.flakeModules.default
        ];

        # Define your Clan
        # See: https://docs.clan.lol/reference/nix-api/clan/
        clan = {
          # Clan wide settings
          meta.name = "khala";

          inventory = {
            machines.auraya.machineClass = "darwin";
          };

          specialArgs = {
            names = {
              hetzner-offsite-backup-host = hetzner-offsite-backup-host;
            };
          };

          # inventory.services.restic.clan-backup = {
          #   roles.client.machines = [
          #     "aiur"
          #   ]; # TODO: How do I reference this programmatically instead of by string?

          #   roles.client.config = {
          #     destinations = {
          #       hetzner-offsite-backup.externalTarget.connectionString =
          #         "rclone:${hetzner-offsite-backup-host}";
          #       hetzner-offsite-backup.externalTarget.rclone = {
          #         host = hetzner-offsite-backup-host;
          #         user = hetzner-offsite-backup-user;
          #         port = 23;
          #       };
          #     };
          #   };
          # };
        };
      });
}

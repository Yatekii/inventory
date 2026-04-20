{ ... }:
let
  hetzner-offsite-backup-user = "u415891";
  hetzner-offsite-backup-host = "${hetzner-offsite-backup-user}.your-storagebox.de";
in
{
  # Define your Clan
  # See: https://docs.clan.lol/reference/nix-api/clan/
  # `flake.clan` (not bare `clan`) is required when setting this from an imported
  # flake-parts module — the `clan` → `flake.clan` rename shim only propagates
  # cleanly at the top level of mkFlake's body.
  flake.clan = {
    # Clan wide settings
    meta.name = "khala";

    inventory = {
      machines.auraya.machineClass = "darwin";

      # clanServices (replaces clanModules)
      instances = {
        # SSH service for all NixOS machines
        sshd = {
          module = {
            name = "sshd";
            input = "clan-core";
          };
          roles.server.machines = {
            aiur = { };
            fenix = { };
          };
        };

        # Root user (replaces root-password clanModule)
        user-root = {
          module = {
            name = "users";
            input = "clan-core";
          };
          roles.default.machines = {
            aiur = { };
            fenix = { };
          };
          roles.default.settings = {
            user = "root";
          };
        };

        # yatekii user (replaces user-password clanModule)
        user-yatekii = {
          module = {
            name = "users";
            input = "clan-core";
          };
          roles.default.machines = {
            aiur = { };
            fenix = { };
          };
          roles.default.settings = {
            user = "yatekii";
            groups = [
              "wheel"
              "networkmanager"
              "video"
              "input"
            ];
          };
        };

        # Trusted nix caches
        trusted-nix-caches = {
          module = {
            name = "trusted-nix-caches";
            input = "clan-core";
          };
          roles.default.machines = {
            aiur = { };
            fenix = { };
          };
        };

      };
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
}

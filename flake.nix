{
  inputs.clan-core.url =
    "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
  # inputs.clan-core.url =
  #   "git+https://git.clan.lol/Yatekii/clan-core?ref=init-restic";
  # inputs.clan-core.url = "path:///Users/yatekii/repos/clan-core";
  inputs.nixpkgs.follows = "clan-core/nixpkgs";
  inputs.conduwuit.url = "github:girlbossceo/conduwuit?tag=0.5.0-rc3";

  inputs.pyproject-nix = {
    url = "github:pyproject-nix/pyproject.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.uv2nix = {
    url = "github:pyproject-nix/uv2nix";
    inputs.pyproject-nix.follows = "pyproject-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.pyproject-build-systems = {
    url = "github:pyproject-nix/build-system-pkgs";
    inputs.pyproject-nix.follows = "pyproject-nix";
    inputs.uv2nix.follows = "uv2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, clan-core, conduwuit, pyproject-nix, uv2nix, ... }:
    let
      hetzner-offsite-backup-user = "u415891";
      hetzner-offsite-backup-host =
        "${hetzner-offsite-backup-user}.your-storagebox.de";
      # Usage see: https://docs.clan.lol
      clan = clan-core.lib.buildClan {
        inherit self;
        # Ensure this is unique among all clans you want to use.
        meta.name = "khalai";

        # All machines in ./machines will be imported.

        # Prerequisite: boot into the installer.
        # See: https://docs.clan.lol/getting-started/installer
        # local> mkdir -p ./machines/machine1
        # local> Edit ./machines/<machine>/configuration.nix to your liking.
        machines = {
          # "aiur" = { clan.core.networking.buildHost = "root@localhost"; };
        };

        inventory.services.restic.clan-backup = {
          roles.client.machines = [
            "aiur"
          ]; # TODO: How do I reference this programmatically instead of by string?

          roles.client.config = {
            destinations = {
              hetzner-offsite-backup.externalTarget.connectionString =
                "rclone:${hetzner-offsite-backup-host}";
              hetzner-offsite-backup.externalTarget.rclone = {
                host = hetzner-offsite-backup-host;
                user = hetzner-offsite-backup-user;
                port = 23;
              };
            };
          };
        };

        specialArgs = {
          sources = {
            conduwuit = conduwuit;
            uv2nix = uv2nix;
            pyproject-nix = pyproject-nix;
          };
          names = {
            hetzner-offsite-backup-host = hetzner-offsite-backup-host;
          };
        };
      };
    in {
      inherit (clan) nixosConfigurations clanInternals;
      # Add the Clan cli tool to the dev shell.
      # Use "nix develop" to enter the dev shell.
      devShells = clan-core.inputs.nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ] (system: {
        default = clan-core.inputs.nixpkgs.legacyPackages.${system}.mkShell {
          packages = [ clan-core.packages.${system}.clan-cli ];
        };
        dev = clan-core.inputs.nixpkgs.legacyPackages.${system}.mkShell {
          packages =
            [ clan-core.inputs.nixpkgs.legacyPackages.${system}.python3 ];
          shellHook = ''
            export GIT_ROOT="$(git rev-parse --show-toplevel)"
            export PATH=$PATH:~/repos/clan-core/pkgs/clan-cli/bin
          '';
        };
      });
    };
}

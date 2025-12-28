{
  inputs = {
    clan-core.url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
    # inputs.clan-core.url =
    #   "git+https://git.clan.lol/Yatekii/clan-core?ref=init-restic";
    # inputs.clan-core.url = "path:///Users/yatekii/repos/clan-core";
    clan-core.inputs.flake-parts.follows = "flake-parts";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # We use flake-parts to modularaize our flake
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";

    # mac-app-util = {
    #   url = "github:hraban/mac-app-util";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      clan-core,
      rust-overlay,
      ...
    }:
    let
      hetzner-offsite-backup-user = "u415891";
      hetzner-offsite-backup-host = "${hetzner-offsite-backup-user}.your-storagebox.de";
      gatherModules = import modules/flake/_gatherModules.nix;
    in
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        inherit self;
      }
      (
        { ... }:
        let
          lib = inputs.nixpkgs.lib;
        in
        {
          # See: https://flake.parts/getting-started
          systems = [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
            "x86_64-darwin"
          ];

          # Import the Clan flake-parts module
          imports = [
            clan-core.flakeModules.default
            inputs.flake-parts.flakeModules.modules
            {
              perSystem =
                { ... }:
                {
                  options.flake.lib = lib.mkOption {
                    type = lib.types.attrsOf lib.types.anything;
                    default = { };
                    description = ''
                      A collection of functions to be used in this flake.
                    '';
                    example = lib.literalExpression ''
                      {
                      }
                    '';
                  };
                };
            }
          ]
          ++ (gatherModules lib [
            ./modules/flake/lib
            ./modules/flake/parts
          ]);

          # Define your Clan
          # See: https://docs.clan.lol/reference/nix-api/clan/
          clan = {
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

                syncthing-auraya = {
                  module = {
                    name = "syncthing";
                    input = "clan-core";
                  };
                  roles.peer.machines."auraya".settings = {
                    extraDevices = {
                      saru = {
                        addresses = [ "dynamic" ];
                        id = "QS4PRFF-K7CAIQ2-HZR52QV-7B3VAFZ-DZSY6PO-XLBATVF-ZV6TGVO-RZBDYQW";
                      };
                    };
                    folders = {
                      documents = {
                        path = "/Users/yatekii/Documents";
                        devices = [ "saru" ];
                      };
                    };
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
      );
}

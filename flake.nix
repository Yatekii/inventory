{
  inputs.clan-core.url =
    "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
  inputs.nixpkgs.follows = "clan-core/nixpkgs";
  inputs.conduwuit.url = "github:girlbossceo/conduwuit?tag=0.5.0-rc3";

  outputs = { self, clan-core, conduwuit, ... }:
    let
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
          # You can also specify additional machines here.
          # aiur = { imports = [ ./aiur/configuration.nix ]; };
        };

        specialArgs = { sources = { conduwuit = conduwuit; }; };
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
      });
    };
}

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

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      # Do NOT follow our nixpkgs — current nixos-unstable has a broken
      # SBCL 2.6.1 build for fare-quasiquote-readtable. mac-app-util's own
      # locked nixpkgs is pre-2.6.0 and builds fine. Restore the follows
      # once nixpkgs PR #505169 (sbcl → 2.6.3) lands on master.
      # inputs.nixpkgs.follows = "nixpkgs";
    };
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
        }
      );
}

{
  inputs.clan-core.url =
    "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
  # inputs.clan-core.url =
  #   "git+https://git.clan.lol/Yatekii/clan-core?ref=init-restic";
  # inputs.clan-core.url = "path:///Users/yatekii/repos/clan-core";
  inputs.nixpkgs.follows = "clan-core/nixpkgs";
  inputs.conduwuit.url = "github:girlbossceo/conduwuit?tag=0.5.0-rc3";

  outputs = { self, nixpkgs, clan-core, conduwuit, ... }:
    let
      terraformStateEncryption = ''
        TF_VAR_passphrase=$(clan secrets get tf-passphrase)
        export TF_VAR_passphrase
        TF_ENCRYPTION=$(cat <<EOF
        key_provider "pbkdf2" "state_encryption_password" {
          passphrase = "$TF_VAR_passphrase"
        }
        method "aes_gcm" "encryption_method" {
          keys = "\''${key_provider.pbkdf2.state_encryption_password}"
        }
        state {
          enforced = true
          method = "\''${method.aes_gcm.encryption_method}"
        }
        EOF
        )

        # shellcheck disable=SC2090
        export TF_ENCRYPTION
      '';
      hetzner-offsite-backup-user = "u415891";
      hetzner-offsite-backup-host =
        "${hetzner-offsite-backup-user}.your-storagebox.de";
      # Usage see: https://docs.clan.lol
      clan = clan-core.lib.clan {
        inherit self;
        # Ensure this is unique among all clans you want to use.
        meta.name = "khala";

        # All machines in ./machines will be imported.

        # Prerequisite: boot into the installer.
        # See: https://docs.clan.lol/getting-started/installer
        # local> mkdir -p ./machines/machine1
        # local> Edit ./machines/<machine>/configuration.nix to your liking.
        machines = {
          # "aiur" = { clan.core.networking.buildHost = "root@localhost"; };
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

        specialArgs = {
          sources = { conduwuit = conduwuit; };
          names = {
            hetzner-offsite-backup-host = hetzner-offsite-backup-host;
          };
          inherit terraformStateEncryption;
        };
      };
    in {
      inherit (clan.config) nixosConfigurations clanInternals;
      clan = clan.config;
      # Add the Clan cli tool to the dev shell.
      # Use "nix develop" to enter the dev shell.
      devShells = clan-core.inputs.nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ] (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tofu = pkgs.opentofu.withPlugins
            (p: [ p.external p.local p.hetznerdns p.null p.tls p.hcloud ]);
          wrappedTofu = pkgs.writeShellScriptBin "tofu" ''
            ${terraformStateEncryption}
            exec ${tofu}/bin/tofu $@
          '';
          xtask = pkgs.writeShellScriptBin "xtask" ''
            cd xtask
            cargo run -- $@
          '';
          getCloudToken = pkgs.writeShellScriptBin "get-hcloud-token" ''
            jq -n --arg secret "$(clan secrets get hcloud-token)" '{"secret":$secret}'
          '';
        in {
          default = pkgs.mkShell {
            packages = [
              clan-core.packages.${system}.clan-cli
              wrappedTofu
              xtask
              getCloudToken
            ];
          };
          dev = pkgs.mkShell {
            packages = [ pkgs.python3 wrappedTofu ];
            shellHook = ''
              export GIT_ROOT="$(git rev-parse --show-toplevel)"
              export PATH=$PATH:~/repos/clan-core/pkgs/clan-cli/bin
            '';
          };
        });

      apps = clan-core.inputs.nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ] (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tofu = pkgs.opentofu.withPlugins
            (p: [ p.external p.local p.hetznerdns p.null p.tls p.hcloud ]);
          wrappedTofu = pkgs.writeShellScriptBin "tofu" ''
            ${terraformStateEncryption}
            exec ${tofu}/bin/tofu -chdir=terraform $@
          '';
          xtask = pkgs.writeShellScriptBin "xtask" ''
            cd xtask
            cargo run -- $@
          '';
          writeInventoryJson = ''
            root=$PWD
            ${xtask}/bin/xtask --root=$root derive-machines-json ${wrappedTofu}/bin/tofu 'terraform.tfstate' machines/machines.json
          '';
          fetchDiskIds = ''
            root=$PWD
            ${xtask}/bin/xtask --root=$root gather-disk-ids machines/machines.json
          '';
          gather-terraform-files = ''
            root=$PWD
            ${xtask}/bin/xtask --root=$root gather-terraform-files machines terraform
          '';
          clean-terraform-files = ''
            root=$PWD
            ${xtask}/bin/xtask --root=$root clean-terraform-files terraform
          '';
        in {
          apply = {
            type = "app";
            program = toString (pkgs.writers.writeBash "apply" ''
              set -eu
              ${terraformStateEncryption}
              ${gather-terraform-files}
              ${wrappedTofu}/bin/tofu init \
              && ${wrappedTofu}/bin/tofu apply
              ${writeInventoryJson}
              ${fetchDiskIds}
              ${clean-terraform-files}
            '');
          };
          # nix run ".#destroy"
          destroy = {
            type = "app";
            program = toString (pkgs.writers.writeBash "destroy" ''
              set -eu
              ${terraformStateEncryption}
              ${gather-terraform-files}
              ${wrappedTofu}/bin/tofu init \
              && ${wrappedTofu}/bin/tofu destroy
              ${writeInventoryJson}
              ${clean-terraform-files}
            '');
          };
        });
    };
}

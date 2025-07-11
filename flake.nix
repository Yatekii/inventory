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
      terraform_state_encryption = ''
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
      clan = clan-core.lib.buildClan {
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
          inherit terraform_state_encryption;
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
      ] (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tofu = pkgs.opentofu.withPlugins
            (p: [ p.external p.local p.hetznerdns p.null p.tls p.hcloud ]);
          terraform = pkgs.writeShellScriptBin "tofu" ''
            ${terraform_state_encryption}
            exec ${tofu}/bin/tofu $@
          '';
        in {
          default = pkgs.mkShell {
            packages = [ clan-core.packages.${system}.clan-cli terraform ];
          };
          dev = pkgs.mkShell {
            packages = [ pkgs.python3 terraform ];
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
            ${terraform_state_encryption}
            exec ${tofu}/bin/tofu -chdir=terraform $@
          '';
          writeInventoryJson = ''
            ${wrappedTofu} show -json terraform.tfstate \
              | jq '.values.root_module.resources' \
              | jq 'map(select(.type == "hcloud_server"))' \
              | jq 'map({ (.name|tostring): { ipv4: .values.ipv4_address } })' \
              | jq add > machines/machines.json
          '';
          fetchDiskId = ''
            machines=$(cat machines/machines.json | jq -r 'to_entries[] | .value.ipv4')
            for ip in $machines; do
              host="root@$ip";
              echo $host
              ssh $host lsblk --output NAME,ID-LINK,FSTYPE,SIZE,MOUNTPOINT
            done
          '';
        in {
          apply = {
            type = "app";
            program = toString (pkgs.writers.writeBash "apply" ''
              set -eu
              ${terraform_state_encryption}
              ${wrappedTofu} init \
              && ${wrappedTofu} apply
              ${writeInventoryJson}
              ${fetchDiskId}
            '');
          };
          # nix run ".#destroy"
          destroy = {
            type = "app";
            program = toString (pkgs.writers.writeBash "destroy" ''
              set -eu
              ${terraform_state_encryption}
              ${wrappedTofu} init \
              && ${wrappedTofu} destroy
              ${writeInventoryJson}
            '');
          };
        });
    };
}

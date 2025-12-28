let
  terraformStateEncryption = ''
    TF_VAR_passphrase=$(clan secrets get tf-passphrase)
    export TF_VAR_passphrase
    TF_ENCRYPTION=$(cat <<EOF
    key_provider "pbkdf2" "state_encryption_password" {
      passphrase = "$TF_VAR_passphrase"
    }
    EOF
    )

    # shellcheck disable=SC2090
    export TF_ENCRYPTION
  '';
in
{
  perSystem =
    {
      pkgs,
      config,
      inputs',
      ...
    }:
    {
      flake.lib.tf.tofu =
        let
          tofu = pkgs.opentofu.withPlugins (p: [
            p.hashicorp_external
            p.hashicorp_local
            p.timohirt_hetznerdns
            p.hashicorp_null
            p.hashicorp_tls
            p.hetznercloud_hcloud
          ]);
          clan-cli = inputs'.clan-core.packages.clan-cli;
          getCloudToken = config.flake.lib.tf.getCloudToken;
          getSshKey = config.flake.lib.tf.getSshKey;
        in
        pkgs.writeShellScriptBin "tofu" ''
          export PATH="${clan-cli}/bin:${getCloudToken}/bin:${getSshKey}/bin:${pkgs.jq}/bin:$PATH"
          ${terraformStateEncryption}
          exec ${tofu}/bin/tofu -chdir=terraform $@
        '';
    };
}

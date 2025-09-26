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
    { pkgs, ... }:
    {
      flake.lib.tf.tofu =
        let
          tofu = pkgs.opentofu.withPlugins (p: [
            p.external
            p.local
            p.hetznerdns
            p.null
            p.tls
            p.hcloud
          ]);
        in
        pkgs.writeShellScriptBin "tofu" ''
          ${terraformStateEncryption}
          exec ${tofu}/bin/tofu -chdir=terraform $@
        '';
    };
}

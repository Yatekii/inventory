{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      lib = config.flake.lib.tf;
    in
    {
      flake.lib.tf.mkTerraformCommand = name: command: {
        type = "app";
        program = toString (
          pkgs.writers.writeBash name ''
            set -eu
            root=$PWD

            function cleanup {
              ${lib.xtask}/bin/xtask --root=$root clean-terraform-files terraform
            }
            trap cleanup EXIT

            # Clean up old terraform files if a previous command failed to clean up.
            cleanup

            # Get all the terraform files from the respective machines.
            ${lib.xtask}/bin/xtask --root=$root gather-terraform-files machines terraform

            ${lib.tf.tofu}/bin/tofu init \
            && ${lib.tf.tofu}/bin/tofu ${command}

            ${lib.xtask}/bin/xtask --root=$root derive-machines-json ${lib.tf.tofu}/bin/tofu 'terraform.tfstate' machines/machines.json

            # Get all the disk IDS from via SSH
            ${lib.xtask}/bin/xtask --root=$root gather-disk-ids machines/machines.json

            # Clean up old terraform files.
            cleanup
          ''
        );
      };
    };
}

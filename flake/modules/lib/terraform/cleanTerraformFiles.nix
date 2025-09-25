{
  perSystem =
    { config, ... }:
    let
      lib = config.flake.lib;
    in
    {
      flake.lib.tf.cleanTerraformFiles = ''
        root=$PWD
        ${lib.xtask}/bin/xtask --root=$root clean-terraform-files terraform
      '';
    };
}

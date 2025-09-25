{
  perSystem =
    { config, ... }:
    let
      lib = config.flake.lib;
    in
    {
      flake.lib.tf.gatherTerraformFiles = ''
        root=$PWD
        ${lib.xtask}/bin/xtask --root=$root gather-terraform-files machines terraform
      '';
    };
}

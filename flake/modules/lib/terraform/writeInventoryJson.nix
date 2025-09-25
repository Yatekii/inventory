{ ... }:
{
  perSystem =
    { config, ... }:
    let
      lib = config.flake.lib;
    in
    {
      flake.lib.tf.writeInventoryJson = ''
        root=$PWD
        ${lib.xtask}/bin/xtask --root=$root derive-machines-json ${lib.tf.tofu}/bin/tofu 'terraform.tfstate' machines/machines.json
      '';
    };
}

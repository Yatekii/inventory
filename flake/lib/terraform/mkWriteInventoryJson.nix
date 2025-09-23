{ ... }:
{
    mkWriteInventoryJson = xtask: tofu: ''
      root=$PWD
      ${xtask}/bin/xtask --root=$root derive-machines-json ${tofu}/bin/tofu 'terraform.tfstate' machines/machines.json
    '';
}

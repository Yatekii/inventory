{ helpers, inputs, ... }:
{
  perSystem = { system, pkgs, ...}: {
    apps = {
      apply-tf = helpers.terraform.mkTerraformCommand "apply-tf" "apply";
    };
  };
}

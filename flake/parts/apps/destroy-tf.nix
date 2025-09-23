{ helpers, inputs, ... }:
{
  perSystem = { system, pkgs, ...}: {
    apps = {
      destroy-tf = helpers.terraform.mkTerraformCommand "destroy-tf" "destroy";
    };
  };
}

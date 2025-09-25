{ self, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      apps = {
        destroy-tf = self.lib.terraform.mkTerraformCommand "destroy-tf" "destroy";
      };
    };
}

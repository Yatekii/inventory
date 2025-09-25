{ self, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      apps = {
        apply-tf = builtins.trace self.lib; # self.lib.terraform.mkTerraformCommand "apply-tf" "apply";
      };
    };
}

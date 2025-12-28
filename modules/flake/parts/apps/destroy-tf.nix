{ self, ... }:
{
  perSystem =
    {
      system,
      pkgs,
      config,
      ...
    }:
    let
      lib = config.flake.lib;
    in
    {
      apps = {
        destroy-tf = lib.tf.mkTerraformCommand "destroy-tf" "destroy";
      };
    };
}

{ ... }:
{
  perSystem =
    {
      system,
      config,
      pkgs,
      ...
    }:
    {
      apps = {
        apply-tf = config.flake.lib.tf.mkTerraformCommand "apply-tf" "apply";
      };
    };
}

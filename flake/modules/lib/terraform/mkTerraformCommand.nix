{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      lib = config.flake.lib.tf;
      lib2 = config.flake.lib.tf2;
    in
    {
      flake.lib.tf.mkTerraformCommand = name: command: {
        type = "app";
        program = toString (
          pkgs.writers.writeBash name ''
            set -eu
            ${lib.gatherTerraformFiles}
            ${lib2.tofu}/bin/tofu init \
            && ${lib2.tofu}/bin/tofu ${command}
            ${lib.fetchDiskIds}
            ${lib.cleanTerraformFiles}
          ''
        );
      };
    };
}

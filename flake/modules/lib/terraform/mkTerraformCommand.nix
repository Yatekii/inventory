{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      lib = config.flake.lib.tf;
    in
    {
      flake.lib.tf.mkTerraformCommand = name: command: {
        type = "app";
        program = toString (
          pkgs.writers.writeBash name ''
            set -eu
            ${lib.gatherTerraformFiles}
            ${lib.tofu}/bin/tofu init \
            && ${lib.tofu}/bin/tofu ${command}
            ${lib.writeInventoryJson}
            ${lib.fetchDiskIds}
            ${lib.cleanTerraformFiles}
          ''
        );
      };
    };
}

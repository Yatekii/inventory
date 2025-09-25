{
  perSystem =
    { config, ... }:
    let
      lib = config.flake.lib;
    in
    {

      flake.lib.tf.fetchDiskIds = ''
        root=$PWD
        ${lib.xtask}/bin/xtask --root=$root gather-disk-ids machines/machines.json
      '';
    };
}

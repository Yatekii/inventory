{ pkgs, lib }:
{
  mkTerraformCommand: command =
    let
      tofu = mkTofu pkgs;
      xtask = mkXtask pkgs;
      writeInventoryJson = mkWriteInventoryJson xtask tofu;
      fetchDiskIds = mkFetchDiskIds xtask;
      gatherTerraformFiles = mkGatherTerraformFiles xtask;
      cleanTerraformFiles = mkCleanTerraformFiles xtask;
    in {
      type = "app";
      program = toString (pkgs.writers.writeBash command ''
        set -eu
        ${gatherTerraformFiles}
        ${tofu}/bin/tofu init \
        && ${tofu}/bin/tofu ${command}
        ${writeInventoryJson}
        ${fetchDiskIds}
        ${cleanTerraformFiles}
      '');
    };
}

{ pkgs, self, ... }:
{
  mkTerraformCommand =
    name: command:
    let
      tofu = self.lib.mkTofu pkgs;
      xtask = self.lib.mkXtask pkgs;
      writeInventoryJson = self.lib.mkWriteInventoryJson xtask tofu;
      fetchDiskIds = self.lib.mkFetchDiskIds xtask;
      gatherTerraformFiles = self.lib.mkGatherTerraformFiles xtask;
      cleanTerraformFiles = self.lib.mkCleanTerraformFiles xtask;
    in
    {
      type = "app";
      program = toString (
        pkgs.writers.writeBash name ''
          set -eu
          ${gatherTerraformFiles}
          ${tofu}/bin/tofu init \
          && ${tofu}/bin/tofu ${command}
          ${writeInventoryJson}
          ${fetchDiskIds}
          ${cleanTerraformFiles}
        ''
      );
    };
}

args:
let
  mkImport = name: {
    ${name} = (import (./. + "/${name}.nix") args).${name};
  };
in
{}
// (mkImport "mkTofu")
// (mkImport "mkXtask")
// (mkImport "mkGetCloudToken")
// (mkImport "mkTerraformCommand")
// (mkImport "mkWriteInventoryJson")
// (mkImport "mkGatherTerraformFiles")
// (mkImport "mkFetchDiskIds")
// (mkImport "mkCleanTerraformFiles")

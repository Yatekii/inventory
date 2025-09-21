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
// (mkImport "mkTofu")
// (mkImport "mkTofu")
// (mkImport "mkTofu")
// (mkImport "mkTofu")

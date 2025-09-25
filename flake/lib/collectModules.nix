{ inputs, ... }:
let
  collectModules =
    dir:
    let
      entries = builtins.readDir dir;
    in
    builtins.concatLists (
      builtins.map (
        name:
        let
          path = dir + "/${name}";
        in
        if builtins.readFileType path == "directory" then
          collectModules path
        else if inputs.nixpkgs.lib.strings.hasSuffix ".nix" name then
          [ path ]
        else
          [ ]
      ) (builtins.attrNames entries)
    );
in
collectModules

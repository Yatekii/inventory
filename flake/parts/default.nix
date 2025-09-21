{ lib, ... }:

let
  importDir = dir:
    let
      entries = builtins.readDir dir;

      # nix files except default.nix
      nixFiles = lib.filterAttrs (n: t:
        t == "regular" && lib.hasSuffix ".nix" n && n != "default.nix"
      ) entries;

      # subdirectories
      subdirs = lib.filterAttrs (n: t: t == "directory") entries;

      # import all nix files as flake-parts modules
      fileModules =
        lib.attrValues (lib.mapAttrs (n: _: dir + "/${n}") nixFiles);

      # recurse into subdirs
      subdirModules =
        lib.flatten (lib.mapAttrsToList (n: _: importDir (dir + "/${n}")) subdirs);

      # if there’s a default.nix *in a subdir*, treat it as a module bundle
      defaultModule =
        if entries ? "default.nix" && dir != ./.   # <-- important!
        then [ (dir + "/default.nix") ]
        else [ ];
    in
      defaultModule ++ fileModules ++ subdirModules;
in
{
  imports = importDir ./.;
}

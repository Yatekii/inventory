lib: paths:
(builtins.concatMap (
  prefix: prefix |> lib.filesystem.listFilesRecursive |> lib.filter (lib.hasSuffix ".module.nix")
) paths)

lib: paths:
(builtins.concatMap (
  prefix:
  prefix
  |> lib.filesystem.listFilesRecursive
  |> lib.filter (lib.hasSuffix ".nix")
  |> lib.filter (
    path:
    path
    |> lib.path.removePrefix prefix
    |> lib.path.subpath.components
    |> lib.all (component: !(lib.hasPrefix "_" component))
  )
) paths)

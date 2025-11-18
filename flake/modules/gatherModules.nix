lib: paths: (
  builtins.concatMap (
    path: path
      |> lib.filesystem.listFilesRecursive
      |> lib.filter (lib.hasSuffix ".nix")
      |> lib.filter (
        path:
        path
        |> lib.path.removePrefix path
        |> lib.path.subpath.components
        |> lib.all (component: !(lib.hasPrefix "_" component))
      )
  ) paths
)

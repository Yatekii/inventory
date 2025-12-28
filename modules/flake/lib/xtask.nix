{
  perSystem =
    { pkgs, ... }:
    {
      flake.lib.xtask = pkgs.writeShellScriptBin "xtask" ''
        cd xtask
        cargo run -- $@
      '';
    };
}

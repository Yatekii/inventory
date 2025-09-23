{ ... }:
{
    mkXtask = pkgs: pkgs.writeShellScriptBin "xtask" ''
      cd xtask
      cargo run -- $@
    '';
}

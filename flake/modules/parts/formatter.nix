{ self, ... }:
{
  perSystem =
    {
      system,
      pkgs,
      ...
    }:
    let
      treefmtEval = self.inputs.treefmt-nix.lib.evalModule pkgs ./formatter/_treefmt.nix;
    in
    {
      formatter = treefmtEval.config.build.wrapper;
    };
}

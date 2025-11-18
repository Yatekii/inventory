{ self, ... }:
{
  perSystem =
    {
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

{ self, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      treefmtEval = self.inputs.treefmt-nix.lib.evalModule pkgs ./formatter/treefmt.nix;
    in
    {
      formatter = treefmtEval.config.build.wrapper;
      checks.formatting = treefmtEval.config.build.check self;
    };
}

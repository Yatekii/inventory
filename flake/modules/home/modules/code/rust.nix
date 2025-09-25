{
  pkgs,
  ...
}:
# let
#   overlays = [ (import inputs.rust-overlay) ];
#   pkgs = import inputs.nixpkgs {
#     inherit system overlays;
#   };
# in
{
  flake.modules.home.packages = [
    pkgs.fzf
    # self.inputs.nixpkgs.legacyPackages.aarch64-darwin.pkgs.rust-bin.beta.latest.default
  ];
}

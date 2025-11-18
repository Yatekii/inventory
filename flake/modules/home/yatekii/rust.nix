{
  self,
  pkgs,
  system,
  ...
}:
let
  # overlays = [ (import inputs.rust-overlay) ];
in
{
  nixpkgs.overlays = [
    (import self.inputs.rust-overlay)
  ];
  home.packages = [
    pkgs.fzf
    pkgs.rust-bin.stable.latest.default
    ];
}

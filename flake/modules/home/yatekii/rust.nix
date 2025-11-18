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
    pkgs.rust-bin.stable.latest.default
  ];
}

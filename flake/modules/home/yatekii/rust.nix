{
  self,
  pkgs,
  ...
}:
{
  nixpkgs.overlays = [
    (import self.inputs.rust-overlay)
  ];

  home.packages = [
    pkgs.rust-bin.stable.latest.default
  ];
}

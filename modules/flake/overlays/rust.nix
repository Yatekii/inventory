{ self, pkgs, ... }:
{
  nixpkgs.overlays = [ self.inputs.rust-overlay.overlays.default ];
  environment.systemPackages = [ pkgs.rust-bin.stable.latest.default ];
}

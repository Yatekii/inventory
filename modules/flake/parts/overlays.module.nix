{ inputs, ... }:
{
  # Canonical registry of overlays for this flake.
  # System and HM modules pick these up via `self.overlays` and apply them
  # via `nixpkgs.overlays = builtins.attrValues self.overlays`.
  flake.overlays = {
    rust = inputs.rust-overlay.overlays.default;
  };
}

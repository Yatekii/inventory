{
  pkgs,
  inputs,
  system,
  ...
}:
{
  flake.modules =
    let
      overlays = [ (import inputs.rust-overlay) ];
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
      };
    in
    {
      home.packages = [
        pkgs.fzf
        throw
        "evaluated!"
        pkgs.legacyPackages.aarch64-darwin.pkgs.rust-bin.beta.latest.default
      ];
    };
}

{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      apps = {
        apply = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "apply" ''
              #!/bin/bash
              sudo env NIX_CONFIG="extra-experimental-features = nix-command flakes pipe-operators" nix run nix-darwin/master#darwin-rebuild -- switch --show-trace --flake .#auraya
            ''
          );
        };
      };
    };
}

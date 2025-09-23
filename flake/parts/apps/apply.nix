{ helpers, inputs, ... }:
{
  perSystem = { system, pkgs, ...}: {
    apps = {
      apply = {
        type = "app";
        program = toString (pkgs.writers.writeBash "apply" ''
          sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#auraya
        '');
      };
    };
  };
}

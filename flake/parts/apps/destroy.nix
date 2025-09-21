{ helpers, inputs, ... }:
{
  perSystem = { system, pkgs, ...}: {
    # Add the Clan cli tool to the dev shell.
    # Use "nix develop" to enter the dev shell.
    apps = {
      destroy = helpers.terraform.mkTerraformCommand "destroy";
    };
  };
}

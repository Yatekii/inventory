# helper.nix
{ pkgs, lib }:
{
  mkGatherTerraformFiles = xtask: ''
    root=$PWD
    ${xtask}/bin/xtask --root=$root gather-terraform-files machines terraform
  '';
}

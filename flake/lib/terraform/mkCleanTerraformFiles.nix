# helper.nix
{ pkgs, lib }:
{
  mkCleanTerraformFiles = xtask: ''
    root=$PWD
    ${xtask}/bin/xtask --root=$root clean-terraform-files terraform
  '';
}

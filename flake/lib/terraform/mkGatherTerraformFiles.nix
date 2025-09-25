# helper.nix
{ ... }:
{
  mkGatherTerraformFiles = xtask: ''
    root=$PWD
    ${xtask}/bin/xtask --root=$root gather-terraform-files machines terraform
  '';
}

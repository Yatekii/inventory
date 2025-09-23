# helper.nix
{ pkgs, lib }:
{
  mkFetchDiskIds = xtask: ''
    root=$PWD
    ${xtask}/bin/xtask --root=$root gather-disk-ids machines/machines.json
  '';
}

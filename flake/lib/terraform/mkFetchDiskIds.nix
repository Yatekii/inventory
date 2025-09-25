# helper.nix
{ ... }:
{
  mkFetchDiskIds = xtask: ''
    root=$PWD
    ${xtask}/bin/xtask --root=$root gather-disk-ids machines/machines.json
  '';
}

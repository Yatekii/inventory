{ lib, ... }:
let
  gatherModules = import ../flake/gatherModules.nix;
in
{
  # System-level shell environment for every host — one module per tool
  # under ./shell/, mirrors the modules/home/user/yatekii/shell/ layout.
  # Auto-gathered; to add a tool drop in a new `<name>.module.nix` and it
  # is picked up on the next evaluation. Each machine imports this one
  # file from its configuration.nix.
  imports = gatherModules lib [ ./shell ];
}

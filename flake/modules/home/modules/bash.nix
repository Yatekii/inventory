# On most devices we will use bash
# On macOS we will use zsh.
# We try to keep the two in sync.

{ pkgs, ... }:
{
  flake.modules.programs.bash.enable = true;
}

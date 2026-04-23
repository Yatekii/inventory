{ pkgs, lib, ... }:
{
  programs.vscode = {
    enable = true;
  };
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      # Add additional package names here
      "vscode"
    ];
}

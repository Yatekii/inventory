{ pkgs, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";
  programs.nixfmt.enable = true;
  # Enable the terraform formatter
  programs.terraform.enable = true;
  # Override the default package
  programs.terraform.package = pkgs.opentofu;
}

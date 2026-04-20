{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cargo-deny
    cargo-dist
    cargo-expand
    cargo-release
    sqlx-cli
    trunk
  ];
}

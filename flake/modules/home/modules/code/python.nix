{
  pkgs,
  ...
}:
{
  flake.modules.home.packages = [
    pkgs.uv
  ];
}

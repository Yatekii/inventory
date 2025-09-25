{ lib, ... }:
{
  options.flake.lib.terraform = lib.mkOption {
    type = lib.types.anything;
    default = { };
    description = ''
      A collection of functions to be used in this flake.
    '';
    example = lib.literalExpression ''
      {
      }
    '';
  };
}

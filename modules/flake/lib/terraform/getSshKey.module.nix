{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      flake.lib.tf.getSshKey = pkgs.writeShellScriptBin "get-ssh-key" ''
        jq -n --arg key "$(clan secrets get main-ssh-key-pub)" '{"key":$key}'
      '';
    };
}

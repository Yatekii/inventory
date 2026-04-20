{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      flake.lib.tf.getCloudToken = pkgs.writeShellScriptBin "get-hcloud-token" ''
        jq -n --arg secret "$(clan secrets get hcloud-token)" '{"secret":$secret}'
      '';
    };
}

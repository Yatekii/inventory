{ ... }:
{
  mkGetCloudToken = pkgs: pkgs.writeShellScriptBin "get-hcloud-token" ''
    jq -n --arg secret "$(clan secrets get hcloud-token)" '{"secret":$secret}'
  '';
}

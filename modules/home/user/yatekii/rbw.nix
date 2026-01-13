{ pkgs, ... }:
let
  url = "https://bitwarden.huesser.dev/";
in
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "noah@huesser.dev";
      base_url = url;
      identity_url = "${url}identity";
      lock_timeout = 7200;
      pinentry = pkgs.pinentry-tty;
    };
  };
}

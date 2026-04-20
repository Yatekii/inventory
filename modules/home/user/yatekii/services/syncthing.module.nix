{ config, pkgs, ... }:
{

  # services.syncthing = {
  #   enable = true;

  #   key = "/run/secrets/path/to/key.pem";
  #   cert = "/run/secrets/path/to/cert.pem";

  #   # Optional GUI settings
  #   guiAddress = "127.0.0.1:8384";

  #   overrideDevices = true;
  #   overrideFolders = true;

  #   # # Syncthing config/state paths
  #   # devices = {
  #   #   "saru" = {
  #   #     id = "QS4PRFF-K7CAIQ2-HZR52QV-7B3VAFZ-DZSY6PO-XLBATVF-ZV6TGVO-RZBDYQW";
  #   #   };

  #   # };
  #   # folders = {
  #   #   "scans" = {
  #   #     path = "/home/yatekii/scans";
  #   #     devices = [
  #   #       "saru"
  #   #     ];
  #   #   };
  #   # };
  # };
}

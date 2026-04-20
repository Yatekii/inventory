{ lib, ... }:
{
  # When only `services.syncthing.settings.{devices,folders}` change, the
  # `syncthing` launchd plist doesn't (same wrapper script), so launchd
  # doesn't restart the daemon, and nothing touches the `.launchd_update_config`
  # watch-file. The `syncthing-init` plist does change (it embeds the new
  # config), but with no fresh watch-file touch it never fires and the running
  # daemon keeps serving the old state.
  #
  # Poke the watch-file after launchd agents are (re)bootstrapped so
  # `syncthing-init` runs and pushes the declared config via the REST API.
  home.activation.syncthingTriggerInit = lib.hm.dag.entryAfter [ "setupLaunchAgents" ] ''
    touch "$HOME/Library/Application Support/Syncthing/.launchd_update_config"
  '';

  services.syncthing = {
    enable = true;

    # Leave `cert` and `key` unset so syncthing keeps using the existing
    # cert.pem / key.pem in `$HOME/Library/Application Support/Syncthing/`.
    # That preserves auraya's device ID already paired with saru.

    settings = {
      devices.saru = {
        id = "A2OS4S4-WQEYYXW-SDQ5R37-DXB6XL7-AUUAPG7-3JMIGHW-Q7IOUM4-KD2LVAD";
        addresses = [ "dynamic" ];
      };

      folders = {
        # Folder IDs must match what the saru container advertises.
        documents-noah = {
          path = "/Users/yatekii/Documents";
          devices = [ "saru" ];
        };
        scans = {
          path = "/Users/yatekii/scans";
          devices = [ "saru" ];
        };
      };
    };
  };
}

{ config, pkgs, ... }:
{
  # Samba file shares for the home LAN — mirrors the ansible-nas layout
  # (amos/media/scans/noah) so existing family device mounts reconnect
  # unchanged. Amos/media/noah are guest-writable; scans is backed by a
  # dedicated `scanner` SMB user because HP MFPs refuse pure-guest SMB
  # write even when the share allows it (they require credentials in the
  # "Log-in Authentication" flow).
  #
  # Ports (445/139 TCP, 137/138 UDP) are opened on all interfaces. Saru
  # sits behind a NAT'd router that doesn't forward SMB externally, so
  # this is LAN-only in practice. If that assumption ever changes, move
  # to `networking.firewall.interfaces.<lan>.allowedTCPPorts`.

  # POSIX identity for the scanner's SMB user. No login shell — SMB auth
  # only. Password comes from a clan var (generated randomly below),
  # pushed into samba's tdbsam via a systemd oneshot on each activation.
  users.groups.scanner = { };
  users.users.scanner = {
    description = "SMB user for the household network scanner";
    isSystemUser = true;
    group = "scanner";
  };

  # `/saru/scans` is fully public: any LAN device — guests via SMB, the
  # scanner authenticating as `scanner`, or any future user — can read
  # and write. 0777 on the directory + create/directory masks on the
  # share make new files world-readable/writable regardless of which
  # SMB identity created them.
  systemd.tmpfiles.rules = [
    "z /saru/scans 0777 - - -"
  ];

  clan.core.vars.generators.scanner-smb = {
    # Random 32-char password; retrieve once with
    #   clan vars get saru scanner-smb/password
    # and paste into the printer's "Log-in Authentication" dialog.
    # Rotate by deleting the var and re-running `clan vars generate saru`.
    script = ''
      ${pkgs.pwgen}/bin/pwgen -s 32 1 > $out/password
    '';
    files.password = {
      secret = true;
      owner = "root";
      mode = "0400";
    };
  };

  systemd.services.samba-scanner-user = {
    description = "Provision scanner SMB user from clan vars";
    wantedBy = [ "multi-user.target" ];
    after = [ "samba-smbd.service" ];
    requires = [ "samba-smbd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      pass=$(cat ${config.clan.core.vars.generators.scanner-smb.files.password.path})
      # Delete-then-add keeps the tdb password in sync with the clan var,
      # so rotating the var is a one-command operation.
      ${pkgs.samba}/bin/smbpasswd -x scanner 2>/dev/null || true
      printf '%s\n%s\n' "$pass" "$pass" | ${pkgs.samba}/bin/smbpasswd -s -a scanner
    '';
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "Saru";
        "netbios name" = "saru";
        "security" = "user";
        # "Bad User" maps unknown usernames to guest — matches how the
        # ansible-nas setup ran and keeps `smbclient //saru/media -N`
        # working without fiddling.
        "map to guest" = "Bad User";
        "guest account" = "nobody";
        # Apple Finder extensions — preserves macOS metadata, stream-based
        # resource forks (no hidden `._` companion files in the shares).
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:encoding" = "native";
      };

      amos = {
        path = "/saru/amos";
        comment = "Amos";
        browseable = "yes";
        writable = "yes";
        "guest ok" = "yes";
        "public" = "yes";
      };

      media = {
        path = "/saru/media";
        comment = "Media";
        browseable = "yes";
        writable = "yes";
        "guest ok" = "yes";
        "public" = "yes";
      };

      scans = {
        path = "/saru/scans";
        comment = "Scans";
        browseable = "yes";
        writable = "yes";
        "guest ok" = "yes";
        "public" = "yes";
        # New files/dirs created through this share are world-rw so
        # anyone else can later read/replace them regardless of which
        # SMB user did the write.
        "create mask" = "0666";
        "directory mask" = "0777";
      };

      noah = {
        path = "/saru/noah";
        comment = "Noah";
        browseable = "yes";
        writable = "yes";
        "guest ok" = "yes";
        "public" = "yes";
      };
    };
  };

  # Windows Service Discovery (wsdd) — makes saru appear in Windows 10+
  # "Network" view without NetBIOS. Mac discovery is already covered by
  # avahi/mDNS (enabled in shared.nix).
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}

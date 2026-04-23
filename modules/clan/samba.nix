{ ... }:
{
  # Samba file shares for the home LAN — mirrors the ansible-nas layout
  # (amos/media/scans/noah) so existing family device mounts reconnect
  # unchanged.
  #
  # Ports (445/139 TCP, 137/138 UDP) are opened on all interfaces. Saru
  # sits behind a NAT'd router that doesn't forward SMB externally, so
  # this is LAN-only in practice. If that assumption ever changes, move
  # to `networking.firewall.interfaces.<lan>.allowedTCPPorts`.

  # Group used to gate write access on the `scans` share. Add the scanner
  # device's smb user (created via `smbpasswd -a <user>`) to this group.
  users.groups.scanner = { };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "Saru";
        "netbios name" = "saru";
        "server min protocol" = "SMB2";
        "client min protocol" = "SMB3";
        "security" = "user";
        "map to guest" = "Bad Password";
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
        writable = "no";
        "guest ok" = "yes";
        "public" = "yes";
        # Guests can read; only `scanner` group members can write (the
        # physical scanner authenticates as a dedicated smb user that
        # belongs to this group).
        "write list" = "@scanner";
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

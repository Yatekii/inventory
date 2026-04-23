{ ... }:
{
  # Samba file shares for the home LAN — mirrors the ansible-nas layout
  # (amos/media/scans/noah) so existing family device mounts reconnect
  # unchanged. All four shares are guest-writable; the scanner device
  # writes to `scans` as a guest (there was never a dedicated scanner
  # user — the ansible `write_list: @scanner` was redundant with
  # `writable: true`).
  #
  # Ports (445/139 TCP, 137/138 UDP) are opened on all interfaces. Saru
  # sits behind a NAT'd router that doesn't forward SMB externally, so
  # this is LAN-only in practice. If that assumption ever changes, move
  # to `networking.firewall.interfaces.<lan>.allowedTCPPorts`.

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "Saru";
        "netbios name" = "saru";
        # SMB1 + NTLMv1 are re-enabled because older scanners/printers on
        # the home LAN only speak those protocols. Modern samba (4.18+)
        # disables them by default; Ubuntu 20.04's 4.11 did not, so
        # everything "just worked" before the migration. Home LAN + no
        # domain auth means the usual security concerns are moot.
        "server min protocol" = "NT1";
        "client min protocol" = "NT1";
        "ntlm auth" = "yes";
        "security" = "user";
        # "Bad User" (not "Bad Password") also maps unknown usernames to
        # guest — older scanner firmware often sends a random/empty user
        # that no POSIX account matches.
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

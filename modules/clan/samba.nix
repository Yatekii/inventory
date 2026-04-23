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
        # SMB1 + NTLMv1 are re-enabled because older scanners/printers on
        # the home LAN only speak those protocols. Modern samba (4.18+)
        # disables them by default; Ubuntu 20.04's 4.11 did not, so
        # everything "just worked" before the migration. Home LAN + no
        # domain auth means the usual security concerns are moot.
        "server min protocol" = "NT1";
        "client min protocol" = "NT1";
        "ntlm auth" = "yes";
        "lanman auth" = "yes";
        # Old printers hang up mid-handshake if samba insists on signing
        # or encryption — both are SMB2+ features they don't implement.
        "server signing" = "auto";
        "smb encrypt" = "off";
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

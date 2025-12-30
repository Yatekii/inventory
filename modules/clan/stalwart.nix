{
  config,
  lib,
  pkgs,
  ...
}:
let
  domainsConfig = import ./domains.nix;
  personsConfig = import ./persons.nix;
  inherit (domainsConfig) domains primaryDomain;
  inherit (personsConfig) persons;
  mailHostname = "mail.${primaryDomain}";
  authDomain = "auth.${primaryDomain}";

  # Certificate directories for each mail domain
  certDir = domain: config.security.acme.certs."mail.${domain}".directory;

  # DKIM selector (used in DNS record name: <selector>._domainkey.<domain>)
  dkimSelector = "default";

  # Helper to get DKIM key path for a domain
  dkimKeyPath = domain: config.clan.core.vars.generators."dkim-${domain}".files.private.path;
in
{
  # Stalwart Mail Server
  # Documentation: https://stalw.art/docs/category/configuration
  # NixOS Wiki: https://wiki.nixos.org/wiki/Stalwart

  services.stalwart-mail = {
    enable = true;
    settings = {
      # Server identification
      server.hostname = mailHostname;

      # HTTP settings for reverse proxy
      # http.url is an expression - use single-quoted string for static URL
      http.url = "'https://${mailHostname}'";
      http.use-x-forwarded = true;

      # Listeners
      server.listener = {
        # SMTP for receiving mail from other servers
        smtp = {
          bind = [ "[::]:25" ];
          protocol = "smtp";
        };

        # Submission for authenticated clients
        submission = {
          bind = [ "[::]:587" ];
          protocol = "smtp";
          tls.required = true;
        };

        # Submissions (implicit TLS)
        submissions = {
          bind = [ "[::]:465" ];
          protocol = "smtp";
          tls.implicit = true;
        };

        # IMAP for mail clients (STARTTLS)
        imap = {
          bind = [ "[::]:143" ];
          protocol = "imap";
          tls.required = true;
        };

        # IMAPS (implicit TLS)
        imaps = {
          bind = [ "[::]:993" ];
          protocol = "imap";
          tls.implicit = true;
        };

        # Management/JMAP interface (behind Caddy)
        http = {
          bind = [ "127.0.0.1:8080" ];
          protocol = "http";
        };
      };

      # TLS certificates - one per domain using security.acme certs
      # Stalwart auto-parses certificate subjects and uses SNI to select the right cert
      certificate = lib.listToAttrs (
        map (d: {
          name = d.name;
          value = {
            cert = "%{file:${certDir d.name}/fullchain.pem}%";
            private-key = "%{file:${certDir d.name}/key.pem}%";
            # Primary domain cert is the default fallback
            default = d.primary;
          };
        }) domains
      );

      # Session authentication using in-memory directory
      # Values are Stalwart expressions - strings must be single-quoted
      session.auth = {
        mechanisms = "[plain, login]";
        directory = "'in-memory'";
      };

      # Storage configuration using RocksDB
      store.db = {
        type = "rocksdb";
        path = "/var/lib/stalwart-mail/data";
        compression = "lz4";
      };

      storage = {
        data = "db";
        fts = "db";
        blob = "db";
        lookup = "db";
        directory = "in-memory";
      };

      # Resolver for outbound mail
      resolver.type = "system";

      # In-memory directory with declarative principals
      # This is completely separate from the "internal" directory that NixOS module creates
      directory."in-memory" = {
        type = "memory";
        principals = lib.mapAttrsToList (userName: userDef: {
          name = userName;
          class = if userDef.admin or false then "admin" else "individual";
          description = userDef.displayName;
          secret = "%{file:${
            config.clan.core.vars.generators."stalwart-user-${userName}-password".files.password.path
          }}%";
          email = userDef.mailAddresses;
        }) persons;
      };

      # Fallback admin for emergency access
      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:${config.clan.core.vars.generators.stalwart-admin-password.files.password.path}}%";
      };

      # Tracer for logging
      tracer.stdout = {
        type = "stdout";
        level = "info";
        ansi = false;
        enable = true;
      };

      # Tracer log file for telemetry (required for web UI telemetry)
      tracer.log = {
        type = "log";
        level = "info";
        path = "/var/lib/stalwart-mail/logs";
        prefix = "stalwart.log";
        enable = true;
      };

      # Enable metrics for Web UI dashboard
      metrics.prometheus.enable = true;

      # DKIM signatures - one per domain
      signature = lib.listToAttrs (
        map (d: {
          name = d.name;
          value = {
            private-key = "%{file:${dkimKeyPath d.name}}%";
            domain = d.name;
            selector = dkimSelector;
            headers = [
              "From"
              "To"
              "Date"
              "Subject"
              "Message-ID"
            ];
            algorithm = "ed25519-sha256";
            canonicalization = "relaxed/relaxed";
          };
        }) domains
      );

      # Sign outgoing mail with DKIM
      queue.outbound.sign = map (d: d.name) domains;
    };
  };

  # Secret generators for passwords and DKIM keys
  clan.core.vars.generators = {
    # Fallback admin password
    stalwart-admin-password = {
      files.password = {
        secret = true;
        owner = "stalwart-mail";
        group = "stalwart-mail";
      };
      script = ''
        ${pkgs.openssl}/bin/openssl rand -base64 64 | tr -d '\n' > "$out/password"
      '';
    };
  }
  # User passwords
  // (lib.mapAttrs' (
    userName: _:
    lib.nameValuePair "stalwart-user-${userName}-password" {
      files.password = {
        secret = true;
        owner = "stalwart-mail";
        group = "stalwart-mail";
      };
      script = ''
        ${pkgs.openssl}/bin/openssl rand -base64 64 | tr -d '\n' > "$out/password"
      '';
    }
  ) persons)
  # DKIM Ed25519 keys for each domain
  // (lib.listToAttrs (
    map (
      d:
      lib.nameValuePair "dkim-${d.name}" {
        files.private = {
          secret = true;
          owner = "stalwart-mail";
          group = "stalwart-mail";
        };
        files.public = {
          secret = false;
        };
        script = ''
          # Generate Ed25519 key pair for DKIM
          ${pkgs.openssl}/bin/openssl genpkey -algorithm Ed25519 -out "$out/private"
          ${pkgs.openssl}/bin/openssl pkey -in "$out/private" -pubout -out "$out/public.pem"

          # Extract raw base64 public key (remove PEM headers) for DNS record
          ${pkgs.gnugrep}/bin/grep -v '^-' "$out/public.pem" | tr -d '\n' > "$out/public"
        '';
      }
    ) domains
  ));

  # ACME certificates for mail domains
  # Use webroot challenge served by Caddy
  security.acme = {
    acceptTerms = true;
    defaults.email = "noah@huesser.dev";

    certs = lib.listToAttrs (
      map (d: {
        name = "mail.${d.name}";
        value = {
          webroot = "/var/lib/acme/acme-challenge";
          group = "acme";
          reloadServices = [ "stalwart-mail" ];
        };
      }) domains
    );
  };

  # Both Caddy and Stalwart need to read ACME certs
  users.users.stalwart-mail.extraGroups = [ "acme" ];
  users.users.caddy.extraGroups = [ "acme" ];

  # Generate autoconfig XML for each domain
  environment.etc = lib.listToAttrs (
    map (d: {
      name = "stalwart/autoconfig-${d.name}.xml";
      value = {
        text = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <clientConfig version="1.1">
            <emailProvider id="${d.name}">
              <domain>${d.name}</domain>
              <displayName>${d.name} Mail</displayName>
              <displayShortName>${d.name}</displayShortName>
              <incomingServer type="imap">
                <hostname>mail.${d.name}</hostname>
                <port>993</port>
                <socketType>SSL</socketType>
                <username>%EMAILLOCALPART%</username>
                <authentication>password-cleartext</authentication>
              </incomingServer>
              <incomingServer type="imap">
                <hostname>mail.${d.name}</hostname>
                <port>143</port>
                <socketType>STARTTLS</socketType>
                <username>%EMAILLOCALPART%</username>
                <authentication>password-cleartext</authentication>
              </incomingServer>
              <outgoingServer type="smtp">
                <hostname>mail.${d.name}</hostname>
                <port>465</port>
                <socketType>SSL</socketType>
                <username>%EMAILLOCALPART%</username>
                <authentication>password-cleartext</authentication>
              </outgoingServer>
              <outgoingServer type="smtp">
                <hostname>mail.${d.name}</hostname>
                <port>587</port>
                <socketType>STARTTLS</socketType>
                <username>%EMAILLOCALPART%</username>
                <authentication>password-cleartext</authentication>
              </outgoingServer>
            </emailProvider>
          </clientConfig>
        '';
      };
    }) domains
  );

  # Caddy serves autoconfig and reverse proxies webadmin/JMAP
  services.caddy.virtualHosts =
    # HTTP handlers for ACME challenges (must be on port 80, not HTTPS)
    lib.listToAttrs (
      map (d: {
        name = "http://mail.${d.name}";
        value = {
          extraConfig = ''
            # Serve ACME HTTP-01 challenges
            handle /.well-known/acme-challenge/* {
              root * /var/lib/acme/acme-challenge
              file_server
            }
            # Redirect everything else to HTTPS
            handle {
              redir https://{host}{uri} permanent
            }
          '';
        };
      }) domains
    )
    # mail.* HTTPS virtual hosts for webadmin/JMAP (using security.acme certs)
    // lib.listToAttrs (
      map (d: {
        name = "mail.${d.name}";
        value = {
          useACMEHost = "mail.${d.name}";
          extraConfig = ''
            # Proxy to Stalwart
            reverse_proxy localhost:8080
          '';
        };
      }) domains
    )
    # autoconfig.* virtual hosts for Thunderbird autodiscovery
    // lib.listToAttrs (
      map (d: {
        name = "autoconfig.${d.name}";
        value = {
          extraConfig = ''
            handle /mail/config-v1.1.xml {
              header Content-Type application/xml
              file_server {
                root /etc/stalwart
                index autoconfig-${d.name}.xml
              }
              rewrite * /autoconfig-${d.name}.xml
            }
          '';
        };
      }) domains
    )
    // {
      # Auth domain for OIDC consumers
      ${authDomain} = {
        extraConfig = ''
          reverse_proxy localhost:8080
        '';
      };
    };

  # Firewall rules for mail
  networking.firewall.allowedTCPPorts = [
    25 # SMTP (inbound mail)
    465 # SMTPS (submission with implicit TLS)
    587 # Submission
    143 # IMAP
    993 # IMAPS
  ];

}

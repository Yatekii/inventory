{
  config,
  lib,
  ...
}:
let
  domainsConfig = import ./domains.nix;
  inherit (domainsConfig) domains primaryDomain;
  mailHostname = "mail.${primaryDomain}";
  authDomain = "auth.${primaryDomain}";
  acmeDir = config.security.acme.certs.${mailHostname}.directory;
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
        };

        # Submissions (implicit TLS)
        submissions = {
          bind = [ "[::]:465" ];
          protocol = "smtp";
          tls.implicit = true;
        };

        # IMAP for mail clients
        imap = {
          bind = [ "[::]:143" ];
          protocol = "imap";
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

      # TLS certificates
      certificate.default = {
        cert = "%{file:${acmeDir}/fullchain.pem}%";
        private-key = "%{file:${acmeDir}/key.pem}%";
      };

      # Session authentication - use OIDC via Kanidm
      session.auth = {
        mechanisms = [
          "PLAIN"
          "LOGIN"
          "OAUTHBEARER"
        ];
        directory = "kanidm";
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
        directory = "kanidm";
      };

      # Kanidm OIDC directory for user authentication
      # Stalwart queries the userinfo endpoint to validate OAUTHBEARER tokens
      # Note: Users must log in once via OIDC before receiving mail
      directory.kanidm = {
        type = "oidc";
        timeout = "15s";

        # Kanidm userinfo endpoint
        endpoint = {
          url = "https://${authDomain}/oauth2/openid/stalwart/userinfo";
          method = "userinfo";
        };

        # Field mappings from OIDC claims
        fields = {
          email = "email";
          username = "preferred_username";
          full-name = "name";
        };
      };

      # Internal directory as fallback for local accounts
      directory.internal = {
        type = "internal";
        store = "db";
      };

      # Queue routing strategy (v0.13+ replaces next-hop)
      queue.strategy.route =
        (map (d: {
          "if" = "rcpt_domain";
          "eq" = d.name;
          "then" = "local";
        }) domains)
        ++ [ "relay" ];

      # Relay configuration for outbound mail
      remote.relay = {
        address = "localhost";
        port = 25;
        protocol = "smtp";
      };

      # Authentication required for outbound
      auth.require = true;

      # Tracer for logging
      tracer.stdout = {
        type = "stdout";
        level = "info";
        ansi = false;
      };
    };
  };

  # ACME settings
  security.acme = {
    acceptTerms = true;
    defaults.email = "noah@huesser.dev";

    certs.${mailHostname} = {
      group = "stalwart-mail";
      extraDomainNames = map (d: "mail.${d.name}") (lib.filter (d: !d.primary) domains);
      # Use webroot with Caddy
      webroot = "/var/lib/acme/acme-challenge";
    };
  };

  # Caddy serves ACME challenges and reverse proxies webadmin/JMAP
  services.caddy.virtualHosts = lib.listToAttrs (
    map (d: {
      name = "mail.${d.name}";
      value = {
        extraConfig = ''
          reverse_proxy localhost:8080
        '';
      };
    }) domains
  );

  # Firewall rules for mail
  networking.firewall.allowedTCPPorts = [
    25 # SMTP (inbound mail)
    465 # SMTPS (submission with implicit TLS)
    587 # Submission
    143 # IMAP
    993 # IMAPS
  ];

  # Ensure stalwart can read ACME certs
  users.users.stalwart-mail.extraGroups = [ "acme" ];
}

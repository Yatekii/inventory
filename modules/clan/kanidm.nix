{
  config,
  pkgs,
  lib,
  ...
}:
let
  domainsConfig = import ./domains.nix;
  personsConfig = import ./persons.nix;
  inherit (domainsConfig) primaryDomain;
  inherit (personsConfig) persons groups;
  authDomain = "auth.${primaryDomain}";
  kanidmPort = 8443;

  # Built-in Kanidm groups that users can be added to
  # These are not created by us, just referenced for membership
  builtinGroups = [ "idm_admins" ];

  # Build custom groups with members from persons (excluding built-in groups)
  kanidmGroups = lib.mapAttrs (
    groupName: groupDef:
    {
      members = lib.attrNames (
        lib.filterAttrs (userName: userDef: lib.elem groupName (userDef.groups or [ ])) persons
      );
    }
    // (removeAttrs groupDef [ "description" ])
  ) groups;

  # Build membership for built-in groups
  # IMPORTANT: For idm_admins, we use overwriteMembers = false to preserve
  # the built-in idm_admin membership (required for provisioning to work)
  builtinGroupMembers = lib.listToAttrs (
    map (groupName: {
      name = groupName;
      value = {
        members = lib.attrNames (
          lib.filterAttrs (userName: userDef: lib.elem groupName (userDef.groups or [ ])) persons
        );
        # Don't overwrite idm_admins - preserve built-in idm_admin member
        overwriteMembers = groupName != "idm_admins";
      };
    }) builtinGroups
  );

  # Use the kanidm package with secret provisioning support
  kanidmPkg = pkgs.kanidmWithSecretProvisioning_1_8;

  # ACME certificate directory for auth domain
  acmeDir = config.security.acme.certs.${authDomain}.directory;

  # Server config file for kanidmd commands (same format as NixOS module)
  serverConfigFile =
    let
      settingsFormat = pkgs.formats.toml { };
      # Filter out null values that TOML doesn't support
      filteredSettings = lib.filterAttrsRecursive (_: v: v != null) config.services.kanidm.serverSettings;
    in
    settingsFormat.generate "server.toml" filteredSettings;
in
{
  # Kanidm Identity Provider
  # Documentation: https://kanidm.github.io/kanidm/stable/

  services.kanidm = {
    enableServer = true;
    enableClient = true;

    # Use the version with secret provisioning support
    package = kanidmPkg;

    serverSettings = {
      domain = authDomain;
      origin = "https://${authDomain}";
      bindaddress = "127.0.0.1:${toString kanidmPort}";

      log_level = "debug";

      # Use ACME certificates
      tls_chain = "${acmeDir}/fullchain.pem";
      tls_key = "${acmeDir}/key.pem";

      # Trust X-Forwarded-For from Caddy
      trust_x_forward_for = true;
    };

    clientSettings = {
      uri = "https://${authDomain}";
    };

    provision = {
      enable = true;
      autoRemove = true;
      acceptInvalidCerts = true;

      adminPasswordFile = config.clan.core.vars.generators.kanidm-admin-password.files.password.path;
      idmAdminPasswordFile =
        config.clan.core.vars.generators.kanidm-idm-admin-password.files.password.path;

      persons = lib.mapAttrs (userName: userDef: {
        displayName = userDef.displayName;
        mailAddresses = userDef.mailAddresses or [ ];
      }) persons;

      groups = kanidmGroups // builtinGroupMembers;

      systems.oauth2.stalwart = {
        displayName = "Stalwart Mail";
        originUrl = "https://mail.${primaryDomain}";
        originLanding = "https://mail.${primaryDomain}";
        public = false;
        basicSecretFile = config.clan.core.vars.generators.oidc-stalwart-secret.files.secret.path;
        scopeMaps = {
          stalwart_users = [
            "openid"
            "email"
            "profile"
          ];
        };
      };
    };
  };

  # ACME certificate for auth domain
  security.acme.certs.${authDomain} = {
    group = "kanidm";
    # Use webroot with Caddy
    webroot = "/var/lib/acme/acme-challenge";
  };

  # All OIDC-related vars generators
  clan.core.vars.generators = {
    # Generate OAuth2 client secret for Stalwart
    oidc-stalwart-secret = {
      files.secret = {
        secret = true;
        owner = "kanidm";
        group = "kanidm";
      };
      script = ''
        ${pkgs.openssl}/bin/openssl rand -base64 64 > "$out/secret"
      '';
    };

    # Admin password for system config (groups, OAuth2 clients)
    kanidm-admin-password = {
      files.password = {
        secret = true;
        owner = "kanidm";
        group = "kanidm";
      };
      script = ''
        ${pkgs.openssl}/bin/openssl rand -base64 64 > "$out/password"
      '';
    };

    # IDM admin password for user management
    kanidm-idm-admin-password = {
      files.password = {
        secret = true;
        owner = "kanidm";
        group = "kanidm";
      };
      script = ''
        ${pkgs.openssl}/bin/openssl rand -base64 64 > "$out/password"
      '';
    };
  }
  // (lib.mapAttrs' (
    userName: _:
    lib.nameValuePair "oidc-user-${userName}-password" {
      files.password = {
        secret = true;
      };
      script = ''
        ${pkgs.openssl}/bin/openssl rand -base64 64 > "$out/password"
      '';
    }
  ) persons);

  # Set initial passwords for users after provisioning
  systemd.services.kanidm-set-user-passwords = {
    description = "Set initial passwords for Kanidm users";
    after = [
      "kanidm.service"
      "kanidm-provision.service"
    ];
    wants = [ "kanidm-provision.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };

    script = ''
      set -euo pipefail

      echo "Setting initial passwords for users..."
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (userName: _: ''
          # Check if ${userName} already has a password set
          CRED_STATUS=$(${kanidmPkg}/bin/kanidm person credential status ${userName} 2>&1 || true)
          if echo "$CRED_STATUS" | grep -q "password: set"; then
            echo "Password already set for ${userName}, skipping"
          else
            echo "Setting initial password for ${userName}"
            USER_PW=$(tr -d '\n' < ${
              config.clan.core.vars.generators."oidc-user-${userName}-password".files.password.path
            })
            KANIDM_RECOVER_ACCOUNT_PASSWORD="$USER_PW" \
              ${kanidmPkg}/bin/kanidmd recover-account -c ${serverConfigFile} --from-environment -- ${userName} 2>&1 || true
          fi
        '') persons
      )}

      echo "Done setting user passwords"
    '';
  };

  # Caddy reverse proxy for auth.huesser.dev
  # Handles ACME challenges and proxies to Kanidm
  services.caddy.virtualHosts."${authDomain}" = {
    extraConfig = ''
      reverse_proxy https://127.0.0.1:${toString kanidmPort} {
        transport http {
          tls_server_name ${authDomain}
          tls_trusted_ca_certs ${acmeDir}/chain.pem
        }
      }
    '';
  };

  # Ensure kanidm can read ACME certs and starts after they're available
  users.users.kanidm.extraGroups = [ "acme" ];

  # Caddy needs to read the ACME chain.pem to trust the upstream Kanidm TLS
  users.users.caddy.extraGroups = [ "kanidm" ];

  systemd.services.kanidm = {
    after = [
      "network-online.target"
      "acme-${authDomain}.service"
    ];
    wants = [
      "network-online.target"
      "acme-${authDomain}.service"
    ];
  };
}

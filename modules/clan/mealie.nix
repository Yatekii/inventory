{ config, ... }:
let
  mealie-domain = "mealie.huesser.dev";
  mealie-port = 9000;
in
{
  imports = [ ./caddy.nix ];

  services.mealie = {
    enable = true;
    port = mealie-port;
    credentialsFile = config.clan.core.vars.generators.mealie-oidc.files.credentials.path;
    settings = {
      BASE_URL = "https://${mealie-domain}";
      TZ = "Europe/Zurich";
      DB_ENGINE = "sqlite";
      OIDC_AUTH_ENABLED = "True";
      OIDC_SIGNUP_ENABLED = "True";
      OIDC_REMEMBER_ME = "True";
      OIDC_ADMIN_GROUP = "mealie-admin";
      OIDC_GROUPS_CLAIM = "urn:zitadel:iam:org:project:254113964105924611:roles";
      OIDC_CONFIGURATION_URL = "https://zitadel.huesser.dev/.well-known/openid-configuration";
    };
  };

  clan.core.vars.generators.mealie-oidc = {
    prompts.client-id = {
      description = "OIDC Client ID for Mealie";
      type = "line";
      persist = true;
    };
    script = ''
      echo "OIDC_CLIENT_ID=$(cat $prompts/client-id)" > $out/credentials
    '';
    files.credentials = {
      secret = true;
    };
  };

  services.caddy.virtualHosts."${mealie-domain}".extraConfig = ''
    reverse_proxy localhost:${toString mealie-port}
  '';
}

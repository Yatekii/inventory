# Central person configuration
# Used by Kanidm and other services that need user information
#
# Note: Group names use underscores (like Kanidm's built-in groups),
# not periods. Periods conflict with Kanidm's SPN format.
{
  persons = {
    noah = {
      displayName = "Noah Hüsser";
      mailAddresses = [ "noah@huesser.dev" ];
      groups = [
        "idm_admins" # Built-in Kanidm group for user/group management
        "stalwart_users"
        "stalwart_admin"
      ];
    };
  };

  # Groups and their descriptions
  # Note: idm_admins is a built-in Kanidm group, don't define it here
  groups = {
    stalwart_users = {
      description = "Access to mail services";
    };
    stalwart_admin = {
      description = "Admin access to Stalwart web UI";
    };
  };
}

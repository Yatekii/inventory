{ config, ... }:
{
  clan.core.vars.generators.main-ssh-key = {
    share = true;
    prompts.main-ssh-key-pub = {
      description = "Main SSH public key for authorized access";
      type = "line";
      persist = true;
    };
    files.main-ssh-key-pub = {
      secret = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    config.clan.core.vars.generators.main-ssh-key.files.main-ssh-key-pub.value
  ];
}

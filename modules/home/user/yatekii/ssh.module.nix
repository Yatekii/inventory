{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "~/.colima/ssh_config" ];
    matchBlocks = {
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      saru = {
        hostname = "home.huesser.dev";
        port = 13377;
        identityFile = "~/.ssh/id_ed25519";
      };
      inspect = {
        hostname = "inspect.probe.rs";
        user = "root";
      };
      tikicraft = {
        hostname = "tikicraft.huesser.dev";
        user = "root";
      };
    };
  };
}

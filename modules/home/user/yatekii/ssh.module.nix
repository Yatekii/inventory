{ ... }:
{
  programs.ssh = {
    enable = true;
    includes = [ "~/.colima/ssh_config" ];
    matchBlocks = {
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

{ ... }:
{
  flake.modules.programs.git = {
    enable = true;
    userName = "Noah Hüsser";
    userEmail = "noahs@huesser.dev";
    aliases = {
      co = "checkout";
      caa = "commit --amend -a --no-edit";
      ca = "commit --amend --no-edit";
      pf = "push -f";
      rb = "!git checkout master && git pull && git checkout - && git rebase master";
    };
    signing = {
      format = "ssh";
      # TODO: Store this keypair in sops or maybe 1Pass or similar?
      key = "/Users/yatekii/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
  };
}

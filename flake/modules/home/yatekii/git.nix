{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Noah Hüsser";
        email = "noah@huesser.dev";
      };
      alias = {
        co = "checkout";
        caa = "commit --amend -a --no-edit";
        ca = "commit --amend --no-edit";
        pf = "push -f";
        rb = "!git checkout master && git pull && git checkout - && git rebase master";
      };
      push.autoSetupRemote = true;
    };
    signing = {
      format = "ssh";
      # TODO: Store this keypair in sops or maybe 1Pass or similar?
      key = "/Users/yatekii/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
  };
}

{ ... }:
{
  programs.zsh = {
    enable = true;
    initContent = ''
      setopt interactivecomments
    '';
  };
}

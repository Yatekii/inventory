{ pkgs, ... }:
{
  home.packages = [ pkgs.fd ];

  home.sessionVariables = {
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git";
  };
}

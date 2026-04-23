{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.zoxide ];

  # zoxide needs shell init to register the `z` / `zi` commands and the
  # cd-shim. nixpkgs has no system-level `programs.zoxide`, so inline it.
  programs.bash.interactiveShellInit = ''
    eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
  '';
  programs.zsh.interactiveShellInit = ''
    eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
  '';
}

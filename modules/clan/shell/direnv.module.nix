{ pkgs, ... }:
{
  # System-level direnv. nixpkgs has `programs.direnv` as a home-manager
  # module but not a NixOS one, so wire package + shell init by hand.
  # nix-direnv (bash-only integration layer) is installed alongside; its
  # hooks live inside the .envrc each repo provides, no shell init needed.
  environment.systemPackages = [
    pkgs.direnv
    pkgs.nix-direnv
  ];

  programs.bash.interactiveShellInit = ''
    eval "$(${pkgs.direnv}/bin/direnv hook bash)"
  '';
  programs.zsh.interactiveShellInit = ''
    eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
  '';
}

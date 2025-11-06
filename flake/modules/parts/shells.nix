{ self, inputs, ... }:
{
  perSystem =
    {
      system,
      pkgs,
      config,
      ...
    }:
    let
      lib = config.flake.lib;
    in
    {
      # Add the Clan cli tool to the dev shell.
      # Use "nix develop" to enter the dev shell.
      devShells =
        let
          tofu = lib.tf.tofu;
          xtask = lib.xtask;
          # TODO: Maybe, instead of putting this command into the devshell, make it a part of flake apps.
          getCloudToken = lib.tf.getCloudToken;
          packages = [
            pkgs.git
            tofu
            xtask
            getCloudToken
          ];
        in
        {
          default = pkgs.mkShell {
            packages = packages ++ [ inputs.clan-core.packages.${system}.clan-cli ];
          };
          dev = pkgs.mkShell {
            inherit packages;
            shellHook = ''
              export GIT_ROOT="$(git rev-parse --show-toplevel)"
              export PATH=$PATH:~/repos/clan-core/pkgs/clan-cli/bin
            '';
          };
        };
    };
}

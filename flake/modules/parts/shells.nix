{ self, inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      # Add the Clan cli tool to the dev shell.
      # Use "nix develop" to enter the dev shell.
      devShells =
        let
          tofu = self.lib.terraform.mkTofu pkgs;
          xtask = self.lib.terraform.mkXtask pkgs;
          getCloudToken = self.lib.terraform.mkGetCloudToken pkgs;
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

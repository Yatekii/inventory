{ self, ... }:
let
  config-home-manager =
    { config, ... }:
    {
      nix-homebrew = {
        # Install Homebrew under the default prefix
        enable = true;

        # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
        enableRosetta = true;

        # User owning the Homebrew prefix
        user = "yatekii";

        # Declarative tap management
        taps = {
          "homebrew/homebrew-core" = self.inputs.homebrew-core;
          "homebrew/homebrew-cask" = self.inputs.homebrew-cask;
        };

        # Enable fully-declarative tap management
        #
        # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
        mutableTaps = false;
      };

      # Align homebrew taps config with nix-homebrew
      homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
    };
in
{
  imports = [
    self.inputs.home-manager.darwinModules.default
    # ../../flake/home/yatekii.nix
    self.inputs.nix-homebrew.darwinModules.nix-homebrew
    config-home-manager
  ];

  # Used for clan to connect to the host when running any of the machine commands.
  clan.core.networking.targetHost = "yatekii@localhost";
  # We are on aarch64 (ARM) from now on.
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  system.primaryUser = "yatekii";

  # Allow touch ID to be used for sudo password prompts.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Do not show the special/accented characters prompt on press and hold of characters.
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;

  homebrew.enable = true;

  # TODO: How can we move this to a module?
  # We use homebrews because the nixpkg is not available on darwin.
  homebrew.casks = [
    "vlc"
  ];
}

{ self, config, ... }:
{
  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = true;

    # We need rosetta installed
    system.activationScripts.extraActivation.text = ''
      softwareupdate --install-rosetta --agree-to-license
    '';

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
}

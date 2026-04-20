{ self, ... }:
{
  imports = [
    self.inputs.mac-app-util.darwinModules.default
  ];

  # Ensure HM users also get trampoline .app bundles so Spotlight can index
  # GUI apps installed through home-manager (e.g. Rectangle).
  home-manager.sharedModules = [
    self.inputs.mac-app-util.homeManagerModules.default
  ];
}

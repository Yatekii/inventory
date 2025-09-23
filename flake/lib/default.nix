args: {
  terraform = import ./terraform args;
  collectModules = (import ./collectModules.nix args);
}

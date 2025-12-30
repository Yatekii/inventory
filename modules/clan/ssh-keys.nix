{ ... }:
let
  # TODO: Replace this hardcoded key with clan vars system
  # See TODO.md for details
  # Run: clan vars generate <machine> to set up proper var-based keys
  mainSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAqpC8tYCxyTBBzf8ZFJlkye/dDY2VfY7knIHMDnHNpe noah@huesser.dev";
in
{
  # Add the SSH key to root's authorized keys
  users.users.root.openssh.authorizedKeys.keys = [
    mainSshKey
  ];
}

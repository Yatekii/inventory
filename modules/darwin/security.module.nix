{ ... }:
{
  # Allow Touch ID to be used for sudo password prompts.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Reattach sudo to the GUI bootstrap session so Touch ID works over SSH/tmux
  # (e.g. when `clan machines update auraya` SSHs back to localhost).
  security.pam.services.sudo_local.reattach = true;
}

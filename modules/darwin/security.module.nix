{ ... }:
{
  # Allow Touch ID to be used for sudo password prompts.
  security.pam.services.sudo_local.touchIdAuth = true;
}

{ ... }:
{
  # Launch Rectangle at login via a home-manager-managed LaunchAgent.
  # Rectangle itself exposes a "launch on login" toggle that uses macOS's
  # SMAppService API, but wiring it that way would leave an imperative
  # step (clicking the toggle inside the app) outside the flake. Managing
  # the LaunchAgent directly keeps the setup declarative and re-bootstrappable.
  #
  # KeepAlive is false so quitting Rectangle stays quit until next login.
  # Rectangle is installed as a homebrew cask in modules/darwin/apps.module.nix.
  launchd.agents.rectangle = {
    enable = true;
    config = {
      Label = "com.knollsoft.Rectangle";
      ProgramArguments = [ "/Applications/Rectangle.app/Contents/MacOS/Rectangle" ];
      RunAtLoad = true;
      KeepAlive = false;
      ProcessType = "Interactive";
    };
  };
}

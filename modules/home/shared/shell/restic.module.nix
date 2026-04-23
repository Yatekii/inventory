{ pkgs, ... }:
{
  # restic CLI for poking at repos directly — complementary to whatever
  # backup orchestration runs as a systemd unit. Useful for ad-hoc
  # restores, `restic snapshots`, `restic ls latest`, etc.
  home.packages = [ pkgs.restic ];
}

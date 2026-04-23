{ pkgs, ... }:
{
  # `sqlite-interactive` ships sqlite3 linked against readline — history,
  # line editing, tab-complete in the REPL. Useful whenever you're
  # poking at vaultwarden/jellyfin/sonarr/... databases.
  home.packages = [ pkgs.sqlite-interactive ];
}

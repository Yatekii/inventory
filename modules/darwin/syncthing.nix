{ ... }:
{
  # Manage syncthing's cert/key through clan vars so the device identity is
  # reproducible across fresh installs. Values are seeded manually from the
  # existing files — see the script's error message for the exact command.
  clan.core.vars.generators.syncthing = {
    files.cert = {
      secret = false;
    };
    files.key = {
      secret = true;
      owner = "yatekii";
      group = "staff";
    };
    script = ''
      test -s "$out/cert" || { echo "run: clan vars set <machine> syncthing/cert < cert.pem" >&2; exit 1; }
      test -s "$out/key"  || { echo "run: clan vars set <machine> syncthing/key  < key.pem"  >&2; exit 1; }
    '';
  };
}

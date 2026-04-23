{ ... }:
{
  services.caddy = {
    enable = true;
    # Staging issues untrusted certs but has no rate limits — good while
    # iterating on the DNS / routing / Caddy config. Re-enable the next
    # time we're adding a new externally-reachable host.
    # acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
    email = "noah@huesser.dev";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}

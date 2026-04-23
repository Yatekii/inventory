{ ... }:
{
  services.caddy = {
    enable = true;
    # Staging issues untrusted certs but has no rate limits — good while
    # iterating on the DNS / routing / Caddy config. Swap to production
    # (comment this line out) once vaultwarden.huesser.dev, and any other
    # new saru-fronted host, answers cleanly on port 80.
    acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
    email = "noah@huesser.dev";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}

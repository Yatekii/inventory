{ ... }: {
  services.caddy = {
    enable = true;
    # acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
    email = "noah@huesser.dev";
  };
}

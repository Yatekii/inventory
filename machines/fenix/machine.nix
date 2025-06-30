{ ... }: {
  resource.hcloud_server.fenix = {
    name = "khala.fenix";
    image = "ubuntu-24.04";
    server_type = "cx22";
    datacenter = "nbg1-dc3";
    backups = false;
  };
}

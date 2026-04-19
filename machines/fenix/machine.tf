resource "hcloud_server" "fenix" {
  name        = "khala.fenix"
  image       = "ubuntu-24.04"
  server_type = "cx23"
  datacenter  = "nbg1-dc3"
  backups     = false
  ssh_keys    = [resource.hcloud_ssh_key.main.id]
}

# Reverse DNS for mail server - critical for email deliverability
resource "hcloud_rdns" "fenix_ipv4" {
  server_id  = hcloud_server.fenix.id
  ip_address = hcloud_server.fenix.ipv4_address
  dns_ptr    = "mail.huesser.dev"
}

resource "hcloud_rdns" "fenix_ipv6" {
  server_id  = hcloud_server.fenix.id
  ip_address = hcloud_server.fenix.ipv6_address
  dns_ptr    = "mail.huesser.dev"
}

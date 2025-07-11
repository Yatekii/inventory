resource "hcloud_server" "fenix" {
  name        = "khala.fenix"
  image       = "ubuntu-24.04"
  server_type = "cx22"
  datacenter  = "nbg1-dc3"
  backups     = false
  ssh_keys    = [resource.hcloud_ssh_key.auraya.id]
}

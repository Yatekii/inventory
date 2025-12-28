terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.51"
    }
  }

  encryption {
    method "aes_gcm" "encryption_method" {
      keys = key_provider.pbkdf2.state_encryption_password
    }
    state {
      enforced = true
      method   = method.aes_gcm.encryption_method
    }
  }
}

data "external" "hcloud-token" {
  program = ["bash", "get-hcloud-token"]
}

data "external" "main-ssh-key" {
  program = ["bash", "get-ssh-key"]
}

provider "hcloud" {
  token = data.external.hcloud-token.result.secret
}

resource "hcloud_ssh_key" "main" {
  name       = "khala.main"
  public_key = data.external.main-ssh-key.result.key
}

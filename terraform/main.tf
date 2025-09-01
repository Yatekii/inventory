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
      method = method.aes_gcm.encryption_method
    }
  }
}

data "external" "hcloud-token" {
  program = ["bash", "get-hcloud-token"]
}

provider "hcloud" {
  token = data.external.hcloud-token.result.secret
}

resource "hcloud_ssh_key" "auraya" {
  name       = "khala.auraya"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/zWoCMabsPjao7AZKfA1jvokjbOBxyGHHKOwTA9krw auraya"
}
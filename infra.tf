# Create SSH Key
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ssh_private_key_openssh" {
  filename        = "${path.module}/${var.prefix}_id_rsa"
  content         = tls_private_key.global_key.private_key_openssh
  file_permission = "0600"
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.module}/${var.prefix}_id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

resource "hcloud_ssh_key" "server_ssh_key" {
  name       = "${var.prefix}-instance-ssh-key"
  public_key = tls_private_key.global_key.public_key_openssh
}

# Single HCloud VPS Instance
resource "hcloud_server" "server" {
  name        = "${var.prefix}-server"
  image       = var.hcloud_image
  server_type = var.hcloud_server
  location    = var.hcloud_location
  ssh_keys    = [hcloud_ssh_key.server_ssh_key.id]

  provisioner "remote-exec" {
    inline = [
      # Add Docker's official GPG key:
      "sudo apt update",
      "sudo apt install ca-certificates curl",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      # Add the repository to Apt sources:
      <<EOF
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      EOF
      ,
      "sudo apt update",
      "sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    ]

    connection {
      type        = "ssh"
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_openssh
      host        = self.ipv4_address
    }
  }
}

# Cloudflare DNS Records
resource "cloudflare_record" "root" {
  zone_id         = var.cloudflare_zone_id
  name            = var.domain
  value           = hcloud_server.server.ipv4_address
  type            = "A"
  ttl             = 1
  proxied         = true
  allow_overwrite = true
  comment         = ""
  tags            = []
}

resource "cloudflare_record" "www" {
  zone_id         = var.cloudflare_zone_id
  name            = "www.${var.domain}"
  value           = hcloud_server.server.ipv4_address
  type            = "A"
  ttl             = 1
  proxied         = true
  allow_overwrite = true
  comment         = ""
  tags            = []
}


resource "null_resource" "ssh_setup" {

  triggers = {
    prefix  = var.prefix
    host_ip = hcloud_server.server.ipv4_address
    ssh_key = tls_private_key.global_key.private_key_openssh
  }

  # Remove Host from known_hosts and Add Credentials to SSH Config
  provisioner "local-exec" {
    command = <<EOF
ssh-keygen -f ~/.ssh/known_hosts -R ${hcloud_server.server.ipv4_address} &&
cat <<EOT >> ~/.ssh/config

Host ${var.prefix}
  HostName ${hcloud_server.server.ipv4_address}
  User root
  IdentityFile ${abspath(path.module)}/${var.prefix}_id_rsa
  IdentitiesOnly yes
EOT
EOF
  }
}

# Infra repo for Hetzner Box

It spins up one Hetzner Cloud box running Ubuntu, installs Docker, configures DNS records on Cloudflare, and sets up the local SSH configuration to connect to the new host.

# Overview
1. Terraform `infra.tf` sets up all necessary resources
   1. Local: SSH key
   2. Hetzner Cloud: VPS with docker installed
   3. Cloudflare: DNS records

# Quickstart
1. Requirements:
   1. [Install Terraform](#requirements-terraform)
   2. Hetzner Account, and API Token
   3. Cloudflare Account, Zone, and API Token (a domain is required)
2. Set up Environment Variables: `terraform.tfvars.example` --> `terraform.tfvars` (see `variables.tf` for a description of each)
3. Run and check output: `terraform init && terraform plan`
4. Run: `terraform apply`
5. Run (local): `ssh [prefix]` (`prefix` variable set in terraform.tfvars) to connect to the Hetzner box
6. Run (ssh'd): `echo -e "HTTP/1.1 200 OK\r\nContent-Length: 11\r\n\r\nhello world" | sudo nc -l -p 80` in the box to see "hello world" when accessing your domain from a browser

# Suggested Usage
The `server` folder contains an example deployment of a static folder `www` and [`n8n`](https://n8n.io/) served via [caddy](https://caddyserver.com/)

1. Upload files via SSH to the box:
   1. `scp <files> <ssh_host>:/<directory>` (e.g. `scp -r server/* prefix:/home` to upload `server` folder contents)
2. SSH into the box and run: `cd /<directory> && docker compose up -d` to start services

## Troubleshooting
With Cloudflare and Caddy, Full (Strict) SSL configuration must be enabled in Cloudflare. https://dash.cloudflare.com/ > SSL/TLS > Configure > Full (Strict)

# Requirements: Terraform
Installing Terraform (on Debian-based Linux distros via apt)
```sh
# Install Terraform (confirm on https://www.terraform.io/ as these commands may be outdated)
wget -qO - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

___

# Notes

📝 There is a known bug with the Cloudflare Terraform Provider. To work around it, it might be necessary to comment out or uncomment the `tags` property in the DNS resources as needed to apply/destroy the configuration.



# Resources
[Hetzner Docs](https://developers.hetzner.com/cloud/)

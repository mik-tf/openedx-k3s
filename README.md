# OpenEdX K3s Deployment

A complete solution for deploying OpenEdX on a K3s Kubernetes cluster using Terraform/OpenTofu for infrastructure provisioning and Ansible for configuration management.

## Overview

This repository combines infrastructure provisioning via Terraform/OpenTofu with automated K3s cluster configuration and OpenEdX deployment using Ansible. The entire deployment process is automated through a single command.

### Features

- **Infrastructure as Code**: Provisions all necessary infrastructure using Terraform/OpenTofu
- **Lightweight Kubernetes**: Uses K3s instead of full Kubernetes
- **Fully Automated**: Single command deployment with `deploy.sh`
- **WireGuard Integration**: Secure network connectivity between nodes
- **High Availability**: Support for HA cluster deployment
- **S3-Compatible Storage**: MinIO integration for STEM content (videos, PDFs, simulations)

## Prerequisites

- Linux/macOS system with bash
- [OpenTofu](https://opentofu.org/) (or Terraform) installed
- [Ansible](https://www.ansible.com/) installed
- [WireGuard](https://www.wireguard.com/) installed
- [jq](https://stedolan.github.io/jq/) installed

## Quick Start

1. Clone this repository:
   ```
   git clone https://github.com/mik-tf/openedx-k3s
   cd openedx-k3s
   ```

2. Configure your deployment:
   ```bash
   # Set up Terraform/OpenTofu configuration
   cp deployment/terraform.tfvars.example deployment/terraform.tfvars
   nano deployment/terraform.tfvars
   
   # Set up OpenEdX configuration
   cp kubernetes/roles/tutor/defaults/main.yml.example kubernetes/roles/tutor/defaults/main.yml
   nano kubernetes/roles/tutor/defaults/main.yml
   ```

3. Deploy with a single command:
   ```
   ./scripts/deploy.sh
   ```

   This will:
   - Provision the infrastructure with OpenTofu
   - Set up WireGuard for secure communications
   - Deploy the K3s cluster
   - Install and configure OpenEdX

## Project Structure

```
openedx-k3s/
├── deployment/         # Terraform/OpenTofu configuration
├── kubernetes/         # Ansible playbooks and K3s configuration
│   ├── roles/          # Ansible roles for cluster setup
│   ├── group_vars/     # Variables for Ansible
│   └── k3s-cluster.yml # Main Ansible playbook
├── scripts/            # Deployment and utility scripts
│   ├── deploy.sh       # Main deployment script
│   ├── wg.sh           # WireGuard setup script
│   └── generate-inventory.sh # Ansible inventory generator
└── docs/               # Additional documentation
```

## Configuration

### Advanced Configuration

Both configuration files (`terraform.tfvars` and `main.yml`) contain comments explaining each setting. You can customize:

- **Infrastructure**: Number of nodes, instance types, region, etc.
- **OpenEdX Platform**: Custom themes, languages, admin credentials
- **Kubernetes**: Storage classes, networking settings

Refer to the example files for all available configuration options.

### STEM Content Storage with MinIO

This deployment includes MinIO integration for storing educational content such as videos, PDFs, and simulations - critical for STEM education. MinIO provides S3-compatible object storage that works seamlessly with OpenEdX.

#### Key Features

- **Video Upload Pipeline**: Properly configured for course creators to upload lecture videos
- **Dedicated Buckets**: Separate storage areas for different content types
  - `openedx`: General course content
  - `openedxuploads`: Student assignments and submissions
  - `videos`: Educational video content
- **Web UI for Management**: Access at `https://minio.YOUR_DOMAIN`

#### Accessing MinIO

After deployment, you can access:
- MinIO storage endpoint: `https://files.YOUR_DOMAIN`
- MinIO admin console: `https://minio.YOUR_DOMAIN`

To retrieve the access credentials:
```bash
tutor config printvalue OPENEDX_AWS_ACCESS_KEY
tutor config printvalue OPENEDX_AWS_SECRET_ACCESS_KEY
```

## Troubleshooting

See the [troubleshooting guide](docs/troubleshooting.md) for common issues and solutions.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

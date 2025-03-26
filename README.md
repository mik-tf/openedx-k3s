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

## Prerequisites

- Linux/macOS system with bash
- [OpenTofu](https://opentofu.org/) (or Terraform) installed
- [Ansible](https://www.ansible.com/) installed
- [WireGuard](https://www.wireguard.com/) installed
- [jq](https://stedolan.github.io/jq/) installed

## Quick Start

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/openedx-k3s.git
   cd openedx-k3s
   ```

2. Deploy with a single command:
   ```
   ./scripts/deploy.sh yourdomain.com
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

### Customizing the Deployment

Edit the configuration files in the `deployment` directory to adjust the infrastructure settings.

### Domain Configuration

Specify your domain when running the deployment script:

```
./scripts/deploy.sh yourdomain.com
```

## Troubleshooting

See the [troubleshooting guide](docs/troubleshooting.md) for common issues and solutions.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

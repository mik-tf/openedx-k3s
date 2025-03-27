#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --- Configuration ---
# Define the path to your Terraform/Tofu configuration directory
TF_CONFIG_DIR_DEPLOYMENT="${REPO_ROOT}/deployment"  # Absolute path to deployment directory
TF_CONFIG_DIR_KUBERNETES="${REPO_ROOT}/kubernetes"  # Absolute path to kubernetes directory

# Domain configuration is now managed through Ansible in tutor/defaults/main.yml

# --- Cleanup (if needed) ---
cd "$TF_CONFIG_DIR_DEPLOYMENT" || exit 1  # Exit if cd fails
# Example: Destroy the 'clean' resources (adapt to your actual setup)
tofu destroy -auto-approve >/dev/null 2>&1 || true
bash "${SCRIPT_DIR}/cleantf.sh"

# --- Terraform/Tofu ---
cd "$TF_CONFIG_DIR_DEPLOYMENT" || exit 1  # Ensure we're in the correct directory

tofu init
if ! tofu apply -auto-approve; then
  echo "Tofu apply failed!"
  # Add additional error handling/notification here
  exit 1
fi

# --- WireGuard and Inventory ---
bash "${SCRIPT_DIR}/wg.sh"
bash "${SCRIPT_DIR}/generate-inventory.sh"

# --- Ansible ---
cd "$TF_CONFIG_DIR_KUBERNETES" || exit 1  # Ensure we're in the correct directory

# Robust Ansible Ping with Retry
MAX_RETRIES=5
RETRY_DELAY=5  # seconds

ansible_ping() {
  local retries=0
  while [[ $retries -lt $MAX_RETRIES ]]; do
    ansible all -m ping
    if [[ $? -eq 0 ]]; then
      echo "Ansible ping successful!"
      return 0  # Exit the function successfully
    fi
    retries=$((retries + 1))
    echo "Ansible ping failed (attempt $retries/$MAX_RETRIES). Retrying in $RETRY_DELAY seconds..."
    sleep "$RETRY_DELAY"
  done

  echo "Ansible ping failed after $MAX_RETRIES attempts."
  return 1  # Indicate failure after all retries
}

if ! ansible_ping; then
    echo "Failed to establish Ansible connection after multiple retries."
    exit 1
fi

# Deploy K3s cluster first
echo "Deploying K3s cluster..."
if ! ansible-playbook k3s-cluster.yml -t common,control,worker; then
  echo "K3s deployment failed!"
  # Add additional error handling/notification here
  exit 1
fi

# Wait for K3s to stabilize
echo "Waiting for K3s cluster to stabilize (60 seconds)..."
sleep 60

# Deploy OpenEdX with Tutor
echo "Deploying OpenEdX with Tutor (using domain from Ansible configuration)..."
if ! ansible-playbook k3s-cluster.yml -t tutor; then
  echo "OpenEdX deployment failed!"
  # Add additional error handling/notification here
  exit 1
fi

# Extract domain from Ansible configuration for DNS setup
OPENEDX_DOMAIN=$(grep -oP 'openedx_domain: "\K[^"]++' "${REPO_ROOT}/kubernetes/roles/tutor/defaults/main.yml")

# Configure DNS
echo "Configuring DNS for OpenEdX (${OPENEDX_DOMAIN})..."
bash "${SCRIPT_DIR}/configure-dns.sh" "${OPENEDX_DOMAIN}"

echo "Deployment completed successfully!"
echo "OpenEdX will be available at: https://${OPENEDX_DOMAIN}"
echo "Studio will be available at: https://studio.${OPENEDX_DOMAIN}"
echo "Admin credentials: username=admin, password=securepassword"
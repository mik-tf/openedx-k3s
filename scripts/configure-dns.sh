#!/bin/bash
set -e

# Get script directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KUBERNETES_DIR="$SCRIPT_DIR/../platform"

# Get domain from command line argument
DOMAIN=${1:-"onlineschool.com"}

# Source the inventory file to get variables
if [ -f "$KUBERNETES_DIR/inventory.ini" ]; then
    # Extract first control plane IP from inventory
    PRIMARY_CONTROL_IP=$(grep -E "^primary_control_ip=" "$KUBERNETES_DIR/inventory.ini" | cut -d'=' -f2)
    PRIMARY_CONTROL_NODE=$(grep -E "^primary_control_node=" "$KUBERNETES_DIR/inventory.ini" | cut -d'=' -f2)
    
    if [ -z "$PRIMARY_CONTROL_IP" ]; then
        echo "Cannot find primary_control_ip in inventory.ini"
        exit 1
    fi
    if [ -z "$PRIMARY_CONTROL_NODE" ]; then
        PRIMARY_CONTROL_NODE="node1"
    fi
else
    echo "Inventory file not found. Make sure deployment was successful."
    exit 1
fi

# Get the load balancer IP from Kubernetes
echo "Fetching IP address for OpenEdX service..."
OPENEDX_IP=$(ssh -o StrictHostKeyChecking=no root@$PRIMARY_CONTROL_IP "kubectl get svc -n openedx tutor-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || echo "")

if [ -z "$OPENEDX_IP" ]; then
    echo "Failed to get OpenEdX LoadBalancer IP. Using primary control plane IP instead."
    OPENEDX_IP=$PRIMARY_CONTROL_IP
fi

echo "Setting up DNS for domain: $DOMAIN with IP: $OPENEDX_IP"

# For demonstration purposes, output how to configure DNS
cat << EOF
===================== DNS Configuration =======================
To access OpenEdX, configure the following DNS records:

$DOMAIN             IN A     $OPENEDX_IP
*.${DOMAIN}         IN A     $OPENEDX_IP

Alternatively, for testing purposes, add these entries to your local /etc/hosts file:

$OPENEDX_IP  $DOMAIN
$OPENEDX_IP  studio.${DOMAIN}
$OPENEDX_IP  preview.${DOMAIN}

Your OpenEdX instance will be accessible at:
- Main site: https://${DOMAIN}
- Studio: https://studio.${DOMAIN}
- Course Preview: https://preview.${DOMAIN}
================================================================
EOF

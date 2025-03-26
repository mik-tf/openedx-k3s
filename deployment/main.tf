terraform {
  required_providers {
    grid = {
      source = "threefoldtech/grid"
    }
  }
}

# Variables
variable "mnemonic" { type = string }
variable "SSH_KEY" { type = string }
variable "control_nodes" { type = list(number) }  # e.g. [6905, 6906, 6907]
variable "worker_nodes" { type = list(number) }   # e.g. [6910, 6911, 6912]
variable "control_cpu" { type = number }
variable "control_mem" { type = number }
variable "control_disk" { type = number }
variable "worker_cpu" { type = number }
variable "worker_mem" { type = number }
variable "worker_disk" { type = number }

provider "grid" {
  mnemonic = var.mnemonic
  network  = "main"
}

# Generate unique mycelium keys/seeds for all nodes
locals {
  all_nodes = concat(var.control_nodes, var.worker_nodes)
}

resource "random_bytes" "mycelium_key" {
  for_each = toset([for n in local.all_nodes : tostring(n)])  # Convert numbers to strings
  length   = 32
}

resource "random_bytes" "ip_seed" {
  for_each = toset([for n in local.all_nodes : tostring(n)])  # Convert numbers to strings
  length   = 6
}

# Mycelium overlay network
resource "grid_network" "k3s_net" {
  name        = "k3s_network"
  nodes       = local.all_nodes
  ip_range    = "10.1.0.0/16"
  add_wg_access = true
  mycelium_keys = {
    for node in local.all_nodes : tostring(node) => random_bytes.mycelium_key[tostring(node)].hex
  }
}

# Unified node deployment
resource "grid_deployment" "nodes" {
  for_each = {
    for idx, node in local.all_nodes : 
    "node_${idx}" => {
      node_id    = node
      is_control = contains(var.control_nodes, node)
    }
  }

  node         = each.value.node_id
  network_name = grid_network.k3s_net.name

  disks {
    name = "data_${each.key}"
    size = each.value.is_control ? var.control_disk : var.worker_disk
  }

  # Additional data disk for worker nodes
  dynamic "disks" {
    for_each = each.value.is_control ? [] : [1]
    content {
      name = "openedx_data_${each.key}"
      size = 100  # Fixed 100GB for OpenEdX data
    }
  }

  vms {
    name       = "vm_${each.key}"
    flist      = "https://hub.grid.tf/tf-official-vms/ubuntu-24.04-full.flist"
    cpu        = each.value.is_control ? var.control_cpu : var.worker_cpu
    memory     = each.value.is_control ? var.control_mem : var.worker_mem
    entrypoint = "/sbin/zinit init"
    publicip   = !each.value.is_control  # Workers get public IPs
    mycelium_ip_seed = random_bytes.ip_seed[tostring(each.value.node_id)].hex  # Convert to string

    env_vars = {
      SSH_KEY = var.SSH_KEY
    }

    # Main data mount
    mounts {
      name        = "data_${each.key}"
      mount_point = "/var/lib/rancher"
    }

    # Conditional OpenEdX data mount for worker nodes
    dynamic "mounts" {
      for_each = each.value.is_control ? [] : [1]
      content {
        name        = "openedx_data_${each.key}"
        mount_point = "/data"
      }
    }

    rootfs_size = 20480
  }
}

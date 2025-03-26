output "wireguard_ips" {
  value = {
    for key, dep in grid_deployment.nodes : 
    key => dep.vms[0].ip
  }
}

output "mycelium_ips" {
  value = {
    for key, dep in grid_deployment.nodes : 
    key => dep.vms[0].mycelium_ip
  }
}

output "worker_public_ips" {
  value = {
    for key, dep in grid_deployment.nodes : 
    key => dep.vms[0].computedip if !contains(var.control_nodes, dep.node)
  }
}

output "wg_config" {
  value = grid_network.k3s_net.access_wg_config
  sensitive = true
}

output "control_nodes" {
  value = [
    for key, dep in grid_deployment.nodes :
    {
      name = key
      ip = dep.vms[0].ip
      mycelium_ip = dep.vms[0].mycelium_ip
      node_id = dep.node
    }
    if contains(var.control_nodes, dep.node)
  ]
}

output "worker_nodes" {
  value = [
    for key, dep in grid_deployment.nodes :
    {
      name = key
      ip = dep.vms[0].ip
      mycelium_ip = dep.vms[0].mycelium_ip
      public_ip = dep.vms[0].computedip
      node_id = dep.node
    }
    if !contains(var.control_nodes, dep.node)
  ]
}

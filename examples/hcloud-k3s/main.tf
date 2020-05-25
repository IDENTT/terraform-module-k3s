provider hcloud {}

module k3s {
  source = "./../.."

  k3s_version = "latest"
  name        = "cluster.local"
  cidr = {
    pods     = "10.42.0.0/16"
    services = "10.43.0.0/16"
  }
  drain_timeout = "30s"

  global_flags = [
    "--flannel-iface ens10",
    "--kubelet-arg cloud-provider=external" # required to use https://github.com/hetznercloud/hcloud-cloud-controller-manager
  ]

  server = {
    name = "server"
    ip   = hcloud_server_network.server_network.ip
    connection = {
      host = hcloud_server.server.ipv4_address
    }

    flags = [
      "--disable-cloud-controller",
    ]
  }

  agents = {
    for i in range(length(hcloud_server.agents)) :
    "${hcloud_server.agents[i].name}_node" => {
      name = "${hcloud_server.agents[i].name}"
      ip   = hcloud_server_network.agents_network[i].ip
      connection = {
        host = hcloud_server.agents[i].ipv4_address
      }

      labels = { "node.kubernetes.io/pool" = hcloud_server.agents[i].labels.nodepool }
      taints = { "dedicated" : hcloud_server.agents[i].labels.nodepool == "gpu" ? "gpu:NoSchedule" : null }
    }
  }
}

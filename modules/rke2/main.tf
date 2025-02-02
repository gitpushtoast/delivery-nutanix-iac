locals {
  uname = var.unique_suffix ? lower("${var.name}-${random_string.uid.result}") : lower(var.name)
}

resource "random_string" "uid" {
  length  = 3
  special = false
  lower   = true
  upper   = false
  numeric = true
}

resource "random_password" "token" {
  length  = 40
  special = false
}

data "nutanix_cluster" "cluster" {
  name = var.nutanix_cluster
}

data "nutanix_subnet" "subnet" {
  subnet_name = var.nutanix_subnet
}

data "nutanix_image" "image" {
  image_name = var.image_name
}

resource "nutanix_virtual_machine" "rke2_bootstrap" {
  name         = "${local.uname}-server-0"
  cluster_uuid = data.nutanix_cluster.cluster.id

  memory_size_mib      = var.server_memory
  num_sockets          = var.server_cpu
  num_vcpus_per_socket = var.server_cpu_cores

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = data.nutanix_image.image.id
    }
    device_properties {
      disk_address = {
        device_index = 0
        adapter_type = "SCSI"
      }
      device_type = "DISK"
    }
    disk_size_mib = var.server_primary_disk_size
  }
  disk_list {
    disk_size_mib = var.server_secondary_disk_size
  }

  nic_list {
    subnet_uuid = data.nutanix_subnet.subnet.id
    dynamic "ip_endpoint_list" {
      for_each = length(var.server_ip_list) != 0 ? [1] : []
      content {
        ip   = var.server_ip_list[0]
        type = "ASSIGNED"
      }
    }
  }

  guest_customization_cloud_init_user_data = base64encode(templatefile("${path.module}/cloud-config.tpl.yaml", {
    hostname         = "${local.uname}-server-0",
    node_user        = var.node_user,
    authorized_keys  = var.ssh_authorized_keys,
    token            = random_password.token.result,
    connect_hostname = "",
    agent            = "",
    tls_san          = var.server_dns_name != "" ? "-T ${var.server_dns_name}" : ""
  }))
}

resource "nutanix_virtual_machine" "rke2_servers" {
  count        = var.server_count - 1 // Subtract one from the user provided var to account for the bootstrap node
  name         = "${local.uname}-server-${count.index + 1}"
  cluster_uuid = data.nutanix_cluster.cluster.id

  memory_size_mib      = var.server_memory
  num_sockets          = var.server_cpu
  num_vcpus_per_socket = var.server_cpu_cores

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = data.nutanix_image.image.id
    }
    device_properties {
      disk_address = {
        device_index = 0
        adapter_type = "SCSI"
      }
      device_type = "DISK"
    }
    disk_size_mib = var.server_primary_disk_size
  }
  disk_list {
    disk_size_mib = var.server_secondary_disk_size
  }

  nic_list {
    subnet_uuid = data.nutanix_subnet.subnet.id
    dynamic "ip_endpoint_list" {
      for_each = length(var.server_ip_list) != 0 ? [1] : []
      content {
        ip   = var.server_ip_list[count.index + 1]
        type = "ASSIGNED"
      }
    }
  }

  guest_customization_cloud_init_user_data = base64encode(templatefile("${path.module}/cloud-config.tpl.yaml", {
    hostname         = "${local.uname}-server-${count.index + 1}",
    count            = count.index,
    uname            = local.uname,
    authorized_keys  = var.ssh_authorized_keys,
    node_user        = var.node_user,
    token            = random_password.token.result,
    connect_hostname = var.server_dns_name != "" ? var.server_dns_name : nutanix_virtual_machine.rke2_bootstrap.nic_list_status.0.ip_endpoint_list[0]["ip"],
    tls_san          = var.server_dns_name != "" ? "-T ${var.server_dns_name}" : ""
    agent            = ""
  }))
}

resource "nutanix_virtual_machine" "rke2_agents" {
  count        = var.agent_count
  name         = "${local.uname}-agent-${count.index}"
  cluster_uuid = data.nutanix_cluster.cluster.id

  memory_size_mib      = var.agent_memory
  num_sockets          = var.agent_cpu
  num_vcpus_per_socket = var.agent_cpu_cores

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = data.nutanix_image.image.id
    }
    device_properties {
      disk_address = {
        device_index = 0
        adapter_type = "SCSI"
      }
      device_type = "DISK"
    }
    disk_size_mib = var.agent_primary_disk_size
  }
  disk_list {
    disk_size_mib = var.agent_secondary_disk_size
  }

  nic_list {
    subnet_uuid = data.nutanix_subnet.subnet.id
  }

  guest_customization_cloud_init_user_data = base64encode(templatefile("${path.module}/cloud-config.tpl.yaml", {
    hostname         = "${local.uname}-agent-${count.index}",
    authorized_keys  = var.ssh_authorized_keys,
    node_user        = var.node_user,
    token            = random_password.token.result,
    connect_hostname = var.server_dns_name != "" ? var.server_dns_name : nutanix_virtual_machine.rke2_bootstrap.nic_list_status.0.ip_endpoint_list[0]["ip"],
    tls_san          = var.server_dns_name != "" ? "-T ${var.server_dns_name}" : ""
    agent            = "-a"
  }))
}

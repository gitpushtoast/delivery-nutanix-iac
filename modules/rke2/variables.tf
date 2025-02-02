variable "nutanix_cluster" {
  description = "The name of the Nutanix cluster to deploy to."
  type        = string
}

variable "nutanix_subnet" {
  description = "The name of the subnet to deploy VMs to."
  type        = string
}

variable "server_ip_list" {
  description = "The list of IPs for server nodes. List must be >= server_count."
  type        = list(string)
  default     = []
}

variable "server_dns_name" {
  description = "The DNS name to use for the server/controlplane. Should route round robin to all IPs under server_ip_list."
  type        = string
  default     = ""
}

variable "name" {
  description = "Name to use for VMs and other resources."
  type        = string
  default     = "rke2"
}

variable "unique_suffix" {
  description = "Whether to add a unique suffix to the name."
  type        = bool
  default     = true
}

variable "server_count" {
  description = "The number of server VMs to deploy."
  type        = number
  default     = 3
}

variable "agent_count" {
  description = "The number of agent VMs to deploy."
  type        = number
  default     = 6
}


variable "server_memory" {
  description = "The amount of memory for each server VM in MiB."
  type        = number
}

variable "server_cpu" {
  description = "The number of CPUs for each server VM."
  type        = number
}

variable "server_cpu_cores" {
  description = "The number of CPU cores, per CPU, for each server VM."
  type        = number
  default     = 1
}

variable "agent_memory" {
  description = "The amount of memory for each agent VM in MiB."
  type        = number
}

variable "agent_cpu" {
  description = "The number of CPUs for each agent VM."
  type        = number
}

variable "agent_cpu_cores" {
  description = "The number of CPU cores, per CPU, for each agent VM."
  type        = number
  default     = 1
}

variable "image_name" {
  description = "The name of the image to use for virtual machines."
  type        = string
}

variable "server_primary_disk_size" {
  description = "The size of the primary disk for server VMs in MiB. Primary disk is the boot disk and contains ephemeral storage."
  type        = number
  default     = 150 * 1024
}

variable "server_secondary_disk_size" {
  description = "The size of the secondary disk for server VMs in MiB. Secondary disk is used for PVC/object storage with rook/ceph."
  type        = number
  default     = 300 * 1024
}

variable "agent_primary_disk_size" {
  description = "The size of the primary disk for agent VMs in MiB. Primary disk is the boot disk and contains ephemeral storage."
  type        = number
  default     = 150 * 1024
}

variable "agent_secondary_disk_size" {
  description = "The size of the secondary disk for agent VMs in MiB. Secondary disk is used for PVC/object storage with rook/ceph."
  type        = number
  default     = 300 * 1024
}

variable "ssh_authorized_keys" {
  description = "A list of authorized public SSH keys to allow for login to the nutanix user on all nodes"
  type        = list(string)
}

variable "node_user" {
  description = "The username to use for the default user on cluster node hosts."
  type        = string
  default     = "nutanix"
}

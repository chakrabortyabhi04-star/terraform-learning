variable "location" {
  type        = string
  default     = "West Europe"
  description = "location variable"
}

variable "resource_group_name" {
  type        = string
  default     = "rg-terraform-learning"
  description = "name of the resource_group"
}

variable "vnet_name" {
  type        = string
  default     = "vnet_learning"
  description = "vnet_learning virtual_network"
}

variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "vnet address space"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "local enviromment"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC dummy-key-for-learning"
}
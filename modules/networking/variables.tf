variable "location" {
  type        = string
  description = "location for modules"
}

variable "resource_group_name" {
  type        = string
  description = "resource group name for modules"
}

variable "environment" {
  type        = string
  description = "enviroment for modules"
}

variable "address_space" {
  type        = list(string)
  description = "variable list for modules"
}
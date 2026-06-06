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
variable "security_rules" {
  type = list(object({
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = string
    destination_port_range       = string
    source_address_prefix        = string
    destination_address_prefix   = string
  }))
  
  description = "dynamic block for security rules"
}
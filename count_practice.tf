


variable "environments" {
  type        = list(string)
  default     = ["dev", "staging", "prod"]
  description = "Deployment environment"
}

resource "azurerm_resource_group" "practice" {
  for_each = toset(var.environments)
  name     = "rg-${each.key}"
  location = "East US"
}
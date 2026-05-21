locals {
common_tags = {
environment = var.environment
project     = "terraform-learning"
}
}

locals {
  project_name = "terraform-learning"
  common_prefix = "${var.environment}-${local.project_name}"
  storage_account_name = replace(local.common_prefix, "-", "")
}
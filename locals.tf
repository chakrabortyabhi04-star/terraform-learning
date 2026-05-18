locals {
common_tags = {
environment = "dev"
project     = "terraform-learning"
}
}

locals {
  project_name = "terraform-learning"

  common_prefix = "${var.environment}-${local.project_name}"
}
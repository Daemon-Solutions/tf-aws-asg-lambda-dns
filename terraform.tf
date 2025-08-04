terraform {
  required_version = "> 0.11"
}

data "aws_region" "current" {
  count = var.enabled ? 1 : 0
}

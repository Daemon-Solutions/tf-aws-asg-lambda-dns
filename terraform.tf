terraform {
  required_version = "> 0.9.0"
}

data "aws_region" "current" {
  count = "${var.enabled ? 1 : 0}"
}

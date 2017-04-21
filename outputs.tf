output "lambda_manage_dns_role_arn" {
  value = "${aws_iam_role.lambda_manage_dns_role.name}"
}

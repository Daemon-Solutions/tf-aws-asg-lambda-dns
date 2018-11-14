output "lambda_manage_dns_role_arn" {
  value = "${join("", aws_iam_role.lambda_manage_dns_role.*.name)}"
}

output "lambda_function_arn" {
  value = "${join("", aws_lambda_function.manage_dns.*.arn)}"
}

output "lambda_function_name" {
  value = "${join("", aws_lambda_function.manage_dns.*.function_name)}"
}

output "sns_topic_arn" {
  value = "${join("", aws_sns_topic.manage_dns_asg_sns.*.arn)}"
}

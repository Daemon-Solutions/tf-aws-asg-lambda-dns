output "lambda_manage_dns_role_arn" {
  value = module.lambda.role_arn
}

output "lambda_function_arn" {
  value = module.lambda.function_arn
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.dns.arn
}


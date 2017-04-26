output "lambda_manage_dns_role_arn" {
  value = "${aws_iam_role.lambda_manage_dns_role.name}"
}

output "lambda_function_arn" {
  value = "${aws_lambda_function.manage_dns.arn}"
}

output "s3_bucket_name" {
  value = "${aws_s3_bucket.bucket_for_lambda_package.id}"
}

output "s3_bucket_arn" {
  value = "${aws_s3_bucket.bucket_for_lambda_package.arn}"
}

output "sns_topic_arn" {
  value = "${aws_sns_topic.manage_dns_asg_sns.arn}"
}

# SNS topic
resource "aws_sns_topic" "manage_dns_asg_sns" {
  count = "${var.enabled ? 1 : 0}"

  name = "${var.sns_topic_name}"
}

# SNS subscription
resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  count = "${var.enabled ? 1 : 0}"

  topic_arn = "${join("", aws_sns_topic.manage_dns_asg_sns.*.arn)}"
  protocol  = "lambda"
  endpoint  = "${join("", aws_lambda_function.manage_dns.*.arn)}"
}

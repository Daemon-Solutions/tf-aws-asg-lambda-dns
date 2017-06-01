# SNS topic
resource "aws_sns_topic" "manage_dns_asg_sns" {
  name = "${var.sns_topic_name}"
}

# SNS subscription
resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  topic_arn = "${aws_sns_topic.manage_dns_asg_sns.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.manage_dns.arn}"
}

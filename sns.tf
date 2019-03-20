# SNS topic
resource "aws_sns_topic" "dns" {
  name = "${var.sns_topic_name}"
}

# SNS subscription
resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  topic_arn = "${aws_sns_topic.dns.arn}"
  protocol  = "lambda"
  endpoint  = "${module.lambda.function_arn}"
}

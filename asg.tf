# ASG notification
resource "aws_autoscaling_notification" "manage_dns_asg_notification" {
  group_names = [
    "${var.asg_names}",
  ]

  notifications = [
    "autoscaling:TEST_NOTIFICATION",
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
  ]

  topic_arn = "${aws_sns_topic.dns.arn}"
}

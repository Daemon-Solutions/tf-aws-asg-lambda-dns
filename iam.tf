# Lambda policy
data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "route53:GetHostedZone",
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]

    resources = [
      "arn:aws:route53:::hostedzone/${var.zone_id}",
    ]
  }

  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "ec2:DescribeInstances",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "*",
    ]
  }
}


# Lambda policy for logging
resource "aws_iam_role_policy" "lambda_manage_dns_logging_policy" {
  count = var.enabled ? 1 : 0

  name = "${var.service}_lambda_dns_logging_policy"
  role = join("", aws_iam_role.lambda_manage_dns_role.*.id)

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

# Lambda policy for managing dns
resource "aws_iam_role_policy" "lambda_manage_dns_policy" {
  count = var.enabled ? 1 : 0

  name = "${var.service}_lambda_route53_policy"
  role = join("", aws_iam_role.lambda_manage_dns_role.*.id)

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:GetHostedZone",
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/${var.zone_id}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
      {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:Get*",
        "secretsmanager:List*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

# Lambda role
resource "aws_iam_role" "lambda_manage_dns_role" {
  count = var.enabled ? 1 : 0

  name_prefix = "${var.service}_lambda_dns"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_lambda_permission" "manage_dns_asg_sns" {
  count = var.enabled ? 1 : 0

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = join("", aws_lambda_function.manage_dns.*.arn)
  principal     = "sns.amazonaws.com"
  source_arn    = join("", aws_sns_topic.manage_dns_asg_sns.*.arn)
}


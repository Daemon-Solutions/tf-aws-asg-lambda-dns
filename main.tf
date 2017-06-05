# Lambda function

## create lambda package
data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = "${path.module}/include/lambda.py"
  output_path = "${path.module}/include/lambda.zip"
}

## create lambda function
resource "aws_lambda_function" "manage_dns" {
  filename         = "${path.module}/include/lambda.zip"
  source_code_hash = "${data.archive_file.lambda_package.output_base64sha256}"
  function_name    = "${var.lambda_function_name}"
  role             = "${aws_iam_role.lambda_manage_dns_role.arn}"
  handler          = "lambda.lambda_handler"
  runtime          = "python2.7"
  timeout          = "60"
  publish          = true

  lifecycle {
    ignore_changes = ["filename"]
  }

  environment {
    variables = {
      ZONE_ID                          = "${var.zone_id}"
      SERVICE                          = "${var.service}"
      PRIVATE_INSTANCE_RECORD_TEMPLATE = "${var.private_instance_record_template}"
      PRIVATE_ASG_RECORD_TEMPLATE      = "${var.private_asg_record_template}"
      PUBLIC_ASG_RECORD_TEMPLATE       = "${var.public_asg_record_template}"
      MANAGE_INSTANCE_DNS              = "${var.manage_instance_dns ? "True" : "False"}"
      MANAGE_PRIVATE_ASG_DNS           = "${var.manage_private_asg_dns ? "True" : "False"}"
      MANAGE_PUBLIC_ASG_DNS            = "${var.manage_public_asg_dns ? "True" : "False"}"
    }
  }
}

# Original TF 0.11.
# Module Tagged v1.9.4 for that TF version (source: Everest VPC)
# Lambda function

## create lambda package
data "archive_file" "lambda_package" {
  count       = var.enabled ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/include/lambda.py"
  output_path = "${path.cwd}/.terraform/tf-aws-asg-lambda-dns-${filemd5("${path.module}/include/lambda.py")}.zip"
}

## create lambda function
resource "aws_lambda_function" "manage_dns" {
  count            = var.enabled ? 1 : 0
  filename         = "./.terraform/tf-aws-asg-lambda-dns-${filemd5("${path.module}/include/lambda.py")}.zip"
  source_code_hash = join("", data.archive_file.lambda_package.*.output_base64sha256)
  function_name    = var.lambda_function_name
  role             = join("", aws_iam_role.lambda_manage_dns_role.*.arn)
  handler          = "lambda.lambda_handler"
  runtime          = var.runtime
  timeout          = "60"

  environment {
    variables = {
      ZONE_ID                          = var.zone_id
      SERVICE                          = var.service
      SLACK_WEBHOOK                    = var.slack_webhook
      ENVIRONMENT                      = var.environment
      PRIVATE_INSTANCE_RECORD_TEMPLATE = var.private_instance_record_template
      PRIVATE_ASG_RECORD_TEMPLATE      = var.private_asg_record_template
      PUBLIC_ASG_RECORD_TEMPLATE       = var.public_asg_record_template
      MANAGE_INSTANCE_DNS              = var.manage_instance_dns ? "True" : "False"
      MANAGE_PRIVATE_ASG_DNS           = var.manage_private_asg_dns ? "True" : "False"
      MANAGE_PUBLIC_ASG_DNS            = var.manage_public_asg_dns ? "True" : "False"
      TTL                              = var.ttl
    }
  }
}

resource "null_resource" "notify_sns_topic" {
  depends_on = [aws_lambda_function.manage_dns]
  count      = var.asg_count == "1"  && var.enabled == "1" ? 1 : 0

  triggers = {
    zone_id                          = var.zone_id
    service                          = var.service
    private_instance_record_template = var.private_instance_record_template
    private_asg_record_template      = var.private_asg_record_template
    public_asg_record_template       = var.public_asg_record_template
  }

  provisioner "local-exec" {
    command = "python ${path.module}/include/publish.py ${data.aws_region.current[0].name} ${element(var.asg_names, count.index)} ${aws_sns_topic.manage_dns_asg_sns[0].arn}"
  }
}


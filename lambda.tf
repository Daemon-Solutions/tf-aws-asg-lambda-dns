# Lambda function
module "lambda" {
  source        = "github.com/claranet/terraform-aws-lambda?ref=v1.2.0"
  function_name = var.lambda_function_name
  description   = "Manages DNS records for ${join(", ", var.asg_names)} AutoScaling Group(s)"
  handler       = "lambda.lambda_handler"
  runtime       = "python3.7"
  layers        = var.lambda_layers
  timeout       = 300
  source_path   = "${path.module}/include/lambda.py"
  policy        = {
    json = data.aws_iam_policy_document.lambda.json
  }

  environment = {
    variables = {
      ZONE_ID                          = var.zone_id
      DNS_ROLE_ARN                     = var.dns_role_arn
      SERVICE                          = var.service
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

resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.dns.arn
}

resource "null_resource" "notify_sns_topic" {
  count = var.asg_count

  triggers = {
    lambda_arn                       = module.lambda.function_arn
    zone_id                          = var.zone_id
    dns_role_arn                     = var.dns_role_arn
    service                          = var.service
    private_instance_record_template = var.private_instance_record_template
    private_asg_record_template      = var.private_asg_record_template
    public_asg_record_template       = var.public_asg_record_template
    manage_instance_dns              = var.manage_instance_dns
    manage_private_asg_dns           = var.manage_private_asg_dns
    manage_public_asg_dns            = var.manage_public_asg_dns
    ttl                              = var.ttl
  }

  provisioner "local-exec" {
    command = "python ${path.module}/include/publish.py ${data.aws_region.current.name} ${element(var.asg_names, count.index)} ${aws_sns_topic.dns.arn}"
  }
}


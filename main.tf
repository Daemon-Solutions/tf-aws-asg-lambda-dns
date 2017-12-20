# Lambda function

## create lambda package
data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = "${path.module}/include/lambda.py"
  output_path = "${path.cwd}/.terraform/tf-aws-asg-lambda-dns-${md5(file("${path.module}/include/lambda.py"))}.zip"
}

## create lambda function
resource "aws_lambda_function" "manage_dns" {
  filename         = "./.terraform/tf-aws-asg-lambda-dns-${md5(file("${path.module}/include/lambda.py"))}.zip"
  source_code_hash = "${data.archive_file.lambda_package.output_base64sha256}"
  function_name    = "${var.lambda_function_name}"
  role             = "${aws_iam_role.lambda_manage_dns_role.arn}"
  handler          = "lambda.lambda_handler"
  runtime          = "python2.7"
  timeout          = "60"

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

resource "null_resource" "notify_sns_topic" {
  depends_on = ["aws_lambda_function.manage_dns"]
  count      = "${length(var.asg_names)}"

  triggers {
    zone_id                          = "${var.zone_id}"
    service                          = "${var.service}"
    private_instance_record_template = "${var.private_instance_record_template}"
    private_asg_record_template      = "${var.private_asg_record_template}"
    public_asg_record_template       = "${var.public_asg_record_template}"
  }

  provisioner "local-exec" {
    command = "python ${path.module}/include/publish.py ${data.aws_region.current.name} ${element(var.asg_names, count.index)} ${aws_sns_topic.manage_dns_asg_sns.arn}"
  }
}

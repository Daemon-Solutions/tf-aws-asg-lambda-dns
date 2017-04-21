# Lambda function

## remove temp files
resource "null_resource" "clean_files" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }

  provisioner "local-exec" {
    command = "rm -rf /tmp/${var.service}-lambda"
  }
}

## save template to a file
data "template_file" "lambda_template" {
  depends_on = ["null_resource.clean_files"]
  template   = "${file("${path.module}/templates/manage_dns.py.tmpl")}"

  vars {
    zone_id                          = "${var.zone_id}"
    service                          = "${var.service}"
    private_instance_record_template = "${var.private_instance_record_template}"
    private_asg_record_template      = "${var.private_asg_record_template}"
    public_asg_record_template       = "${var.public_asg_record_template}"
    manage_instance_dns              = "${var.manage_instance_dns ? "True" : "False"}"
    manage_private_asg_dns           = "${var.manage_private_asg_dns ? "True" : "False"}"
    manage_public_asg_dns            = "${var.manage_public_asg_dns ? "True" : "False"}"
  }
}

resource "null_resource" "save_template_to_file" {
  depends_on = ["data.template_file.lambda_template"]

  triggers = {
    lambda_version = "${var.lambda_version}"
  }

  provisioner "local-exec" {
    command = "mkdir -p /tmp/${var.service}-lambda && echo \"${data.template_file.lambda_template.rendered}\" > /tmp/${var.service}-lambda/manage_dns.py"
  }
}

## create lambda package
data "archive_file" "create_lambda_package" {
  depends_on  = ["null_resource.save_template_to_file"]
  type        = "zip"
  source_dir  = "/tmp/${var.service}-lambda"
  output_path = "/tmp/${var.service}-lambda/manage_dns-${var.lambda_version}.zip"
}

## upload lambda package to s3
resource "aws_s3_bucket_object" "upload_lambda_package" {
  depends_on = ["data.archive_file.create_lambda_package"]
  bucket     = "${aws_s3_bucket.bucket_for_lambda_package.id}"
  key        = "manage_dns-${var.lambda_version}.zip"
  source     = "/tmp/${var.service}-lambda/manage_dns-${var.lambda_version}.zip"
}

## create lambda fucntion
resource "aws_lambda_function" "manage_dns" {
  depends_on        = ["aws_s3_bucket_object.upload_lambda_package"]
  s3_bucket         = "${aws_s3_bucket.bucket_for_lambda_package.id}"
  s3_key            = "manage_dns-${var.lambda_version}.zip"
  s3_object_version = "null"
  function_name     = "manage_dns-${var.service}"
  role              = "${aws_iam_role.lambda_manage_dns_role.arn}"
  handler           = "manage_dns.lambda_handler"
  runtime           = "python2.7"
  timeout           = "60"
  publish           = true
}

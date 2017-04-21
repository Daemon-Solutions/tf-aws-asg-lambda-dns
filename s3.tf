# s3 bucket for lambda package
resource "aws_s3_bucket" "bucket_for_lambda_package" {
  bucket = "${var.service}-lambda-${uuid()}"
  acl    = "private"
  region = "${var.aws_region}"

  tags {
    Name = "service-lambda"
  }

  lifecycle {
    ignore_changes = ["bucket"]
  }
}

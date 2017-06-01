variable "aws_region" {
  default = "eu-west-1"
}

variable "lambda_function_name" {}

variable "lambda_version" {
  description = "Version for lambda function"
}

variable "zone_id" {
  description = "Id of a zone file to add records to"
}

variable "asg_name" {
  description = "Name of AutoscalingGroup to attach this Lambda function to"
}

variable "sns_topic_name" {
  description = "Name for SNS topic"
}

variable "service" {
  description = "ASG service name, ex: bastion. This will be prefix for DNS records."
}

variable "private_instance_record_template" {
  description = "What should instance's private DNS record look like, choices are: 'service(.|-)az.domain' (ex: bastion.eu-west-1a.domain.tld) or 'service(.|-)instanceid.domain' (ex: web-i-0a3c65796c57c68d3.domain.tld)"
  default     = "service.az.domain"
}

variable "private_asg_record_template" {
  description = "What should asg's private DNS record look like, choices are: 'service.internal.domain' (ex: bastion.internal.domain.tld) and 'service.domain' (ex: bastion.domain.tld)"
  default     = "service.internal.domain"
}

variable "public_asg_record_template" {
  description = "What should asg's public DNS record look like, choices are: 'service.domain' (ex: bastion.domain.tld)"
  default     = "service.domain"
}

variable "manage_instance_dns" {
  description = "Whether to manage dns records for asg instances"
  default     = true
}

variable "manage_private_asg_dns" {
  description = "Whether to manage private dns records for asg"
  default     = false
}

variable "manage_public_asg_dns" {
  description = "Whether to manage public dns records for asg"
  default     = false
}

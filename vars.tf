variable "lambda_function_name" {}

variable "zone_id" {
  description = "Id of a zone file to add records to"
}

variable "asg_names" {
  description = "Name of AutoscalingGroups to attach this Lambda function to"
  type        = "list"
}

variable "sns_topic_name" {
  description = "Name for SNS topic"
}

variable "service" {
  description = "ASG service name, ex: bastion. This will be prefix for DNS records."
}

variable "private_instance_record_template" {
  description = "What should instance's private DNS record look like"
  default     = "service.az.domain"
}

variable "private_asg_record_template" {
  description = "What should asg's private DNS record look like"
  default     = "service.internal.domain"
}

variable "public_asg_record_template" {
  description = "What should asg's public DNS record look like"
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

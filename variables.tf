variable "lambda_function_name" {
  description = "The name of the Lambda Function to create, which will manage the Autoscaling Groups"
  type        = "string"
}

variable "lambda_layers" {
  description = "List of Lambda Layer Version ARNs to attach to the Lambda Function"
  type        = "list"
  default     = []
}

variable "zone_id" {
  description = "Id of a zone file to add records to"
  type        = "string"
}

variable "dns_role_arn" {
  description = "ARN of a role to assume to manage DNS records. Useful if DNS zone is in different account"
  type        = "string"
  default     = ""
}

variable "asg_names" {
  description = "The Autoscaling Group names to attach to this Lambda Function"
  type        = "list"
}

variable "asg_count" {
  description = "Number of the Autoscaling Groups defined in asg_names variable. Only here because count cannot be computed"
  default     = 1
}

variable "sns_topic_name" {
  description = "Name for the SNS topic which will handle notifications of instance launch and terminate events"
  type        = "string"
}

variable "service" {
  description = "Autoscaling Group service name, e.g. 'bastion'. This will be prefix for DNS records."
  type        = "string"
}

variable "private_instance_record_template" {
  description = "The fully qualified domain name format for private instance DNS records"
  default     = "service.az.domain"
}

variable "private_asg_record_template" {
  description = "The fully qualified domain name format for private Autoscaling Group DNS records"
  default     = "service.internal.domain"
}

variable "public_asg_record_template" {
  description = "The fully qualified domain name format for public Autoscaling Group DNS records"
  default     = "service.domain"
}

variable "manage_instance_dns" {
  description = "Whether to manage DNS records for Autoscaling Group instances"
  default     = true
}

variable "manage_private_asg_dns" {
  description = "Whether to manage DNS records for private Autoscaling Group instances"
  default     = false
}

variable "manage_public_asg_dns" {
  description = "Whether to manage DNS records for public Autoscaling Group instances"
  default     = false
}

variable "ttl" {
  description = "TTL value for the DNS record(s)"
  default     = 60
}

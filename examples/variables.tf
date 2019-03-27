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
  default     = false
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
  default = 60
}

variable "aws_region" {
  default = "eu-west-1"
}

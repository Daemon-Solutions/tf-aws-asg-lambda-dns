data "aws_availability_zones" "available" {}

data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

resource "random_string" "random" {
  length  = 8
  special = false
  number  = false
}

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  name               = "terraform-aws-asg-dns"
  cidr               = "10.0.0.0/24"
  azs                = "${data.aws_availability_zones.available.names}"
  public_subnets     = ["10.0.0.0/26", "10.0.0.64/26", "10.0.0.128/26"]
  enable_nat_gateway = false
  enable_vpn_gateway = false
}

resource "aws_launch_configuration" "lc" {
  associate_public_ip_address = true
  name                        = "terraform-aws-asg-dns"
  image_id                    = "${data.aws_ami.ami.image_id}"
  instance_type               = "t2.micro"
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier       = ["${module.vpc.public_subnets}"]
  name                      = "terraform-aws-asg-dns"
  max_size                  = 3
  min_size                  = 3
  health_check_grace_period = 300
  health_check_type         = "ELB"
  launch_configuration      = "${aws_launch_configuration.lc.name}"
}

resource "aws_route53_zone" "zone" {
  name          = "${lower(random_string.random.result)}.com"
  force_destroy = true
}

module "dns" {
  source                           = "../"
  zone_id                          = "${aws_route53_zone.zone.zone_id}"
  asg_names                        = ["${aws_autoscaling_group.asg.name}"]
  sns_topic_name                   = "terraform-aws-asg-dns-${random_string.random.result}"
  service                          = "test"
  lambda_function_name             = "terraform-aws-asg-dns-${random_string.random.result}"
  manage_instance_dns              = "${var.manage_instance_dns}"
  manage_private_asg_dns           = "${var.manage_private_asg_dns}"
  manage_public_asg_dns            = "${var.manage_public_asg_dns}"
  private_instance_record_template = "${var.private_instance_record_template}"
  private_asg_record_template      = "${var.private_asg_record_template}"
  public_asg_record_template       = "${var.public_asg_record_template}"
  ttl                              = "${var.ttl}"
}

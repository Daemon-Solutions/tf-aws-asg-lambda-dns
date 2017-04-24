# DNS support for ASG instances

This is work in progress, more details will be added soon

## Usage

module "dnsmagic" {
    source = "../modules/tf-aws-asg-lambda-dns/"
    zone_id = "Z2FA3UHII7N4VI"
    asg_name = "${aws_autoscaling_group.bar.name}"
    sns_topic_name = "test-topic"
    service = "asg-dns"
    manage_instance_dns = true
    manage_private_asg_dns = true
    lambda_version = "v0.5"
}

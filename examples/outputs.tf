output "zone_name" {
  value = "${aws_route53_zone.zone.name}"
}

output "zone_id" {
  value = "${aws_route53_zone.zone.id}"
}

output "asg_name" {
  value = "${aws_autoscaling_group.asg.name}"
}

output "asg_id" {
  value = "${aws_autoscaling_group.asg.id}"
}

output "service" {
  value = "test"
}

output "ttl" {
  value = "${var.ttl}"
}

output "private_instance_record_template" {
  value = "${var.private_instance_record_template}"
}

output "private_asg_record_template" {
  value = "${var.private_asg_record_template}"
}

output "public_asg_record_template" {
  value = "${var.public_asg_record_template}"
}

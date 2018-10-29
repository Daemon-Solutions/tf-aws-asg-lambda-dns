tf-aws-asg-lambda-dns
===============================

Route53 support for ASG instances.

Valid record templates are:
- service.domain
- service.az.domain
- service-az.domain
- service.az_short.domain
- service-az_short.domain
- service.instanceid.domain
- service-instanceid.domain
- service.internal.region.domain
- service.internal.domain
- service-internal.domain
- service.region.domain
- service-region.domain

Note that templates containing `az`, `az_short` or `instanceid` are not available for `ASG` type records ( `private_asg_record_template` and `public_asg_record_template`).


Usage
-----

```js

module "dnsmagic" {
  source                           = "../modules/tf-aws-asg-lambda-dns/"
  zone_id                          = "Z2FA3UHII7N4VI"
  asg_names                        = ["${aws_autoscaling_group.bar.name}"]
  asg_count                        = 1
  sns_topic_name                   = "bastions_dns_lambda"
  lambda_function_name             = "handle_dns_for_bastions"
  service                          = "bastion"
  manage_instance_dns              = true
  private_instance_record_template = "service.instanceid.domain"
  manage_private_asg_dns           = true
  ttl                              = 60
}

```

Variables
---------

See [variables file](vars.tf)

Outputs
-------

See [optputs file](outputs.tf)

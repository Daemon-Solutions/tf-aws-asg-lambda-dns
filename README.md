tf-aws-asg-lambda-dns
===============================

Route53 support for ASG instances

Usage
-----

```js 

module "dnsmagic" {
    source = "../modules/tf-aws-asg-lambda-dns/"
    zone_id = "Z2FA3UHII7N4VI"
    asg_names = ["${aws_autoscaling_group.bar.name}"]
    sns_topic_name = "bastions_dns_lambda"
    lambda_function_name = "handle_dns_for_bastions"
    service = "bastion"
    manage_instance_dns = true
    private_instance_record_template = "service.instanceid.domain"
    manage_private_asg_dns = true
}
```

Variables
---------

See [variables file](vars.tf)

Outputs
-------

See [optputs file](outputs.tf)

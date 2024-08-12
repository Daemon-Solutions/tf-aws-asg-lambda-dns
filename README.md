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
  asg_names                        = [aws_autoscaling_group.bar.name]
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

See [outputs file](outputs.tf)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.11 |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_notification.manage_dns_asg_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_notification) | resource |
| [aws_iam_role.lambda_manage_dns_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda_manage_dns_logging_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.lambda_manage_dns_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.manage_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.manage_dns_asg_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sns_topic.manage_dns_asg_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.sns_topic_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [null_resource.notify_sns_topic](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [archive_file.lambda_package](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asg_count"></a> [asg\_count](#input\_asg\_count) | Number of the Autoscaling Groups defined in asg\_names variable. Only here because count cannot be computed | `string` | `"1"` | no |
| <a name="input_asg_names"></a> [asg\_names](#input\_asg\_names) | Name of the Autoscaling Groups to attach this Lambda Function to | `list(string)` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Enable or disable the Lambda DNS functionality. | `string` | `"1"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment | `string` | n/a | yes |
| <a name="input_lambda_function_name"></a> [lambda\_function\_name](#input\_lambda\_function\_name) | The name of the Lambda Function to create, which will manage the Autoscaling Groups | `string` | n/a | yes |
| <a name="input_manage_instance_dns"></a> [manage\_instance\_dns](#input\_manage\_instance\_dns) | Whether to manage DNS records for Autoscaling Group instances | `bool` | `true` | no |
| <a name="input_manage_private_asg_dns"></a> [manage\_private\_asg\_dns](#input\_manage\_private\_asg\_dns) | Whether to manage DNS records for private Autoscaling Group instances | `bool` | `false` | no |
| <a name="input_manage_public_asg_dns"></a> [manage\_public\_asg\_dns](#input\_manage\_public\_asg\_dns) | Whether to manage DNS records for public Autoscaling Group instances | `bool` | `false` | no |
| <a name="input_pd_escalation_policy"></a> [pd\_escalation\_policy](#input\_pd\_escalation\_policy) | PagerDuty Escalation Policy | `string` | n/a | yes |
| <a name="input_pd_priority"></a> [pd\_priority](#input\_pd\_priority) | PagerDuty Priority ID | `string` | n/a | yes |
| <a name="input_pd_service"></a> [pd\_service](#input\_pd\_service) | PagerDuty Service ID | `string` | n/a | yes |
| <a name="input_pd_user_email"></a> [pd\_user\_email](#input\_pd\_user\_email) | PagerDuty Registered User Email | `string` | n/a | yes |
| <a name="input_private_asg_record_template"></a> [private\_asg\_record\_template](#input\_private\_asg\_record\_template) | The fully qualified domain name format for private Autoscaling Group DNS records | `string` | `"service.internal.domain"` | no |
| <a name="input_private_instance_record_template"></a> [private\_instance\_record\_template](#input\_private\_instance\_record\_template) | The fully qualified domain name format for private instance DNS records | `string` | `"service.az.domain"` | no |
| <a name="input_public_asg_record_template"></a> [public\_asg\_record\_template](#input\_public\_asg\_record\_template) | The fully qualified domain name format for public Autoscaling Group DNS records | `string` | `"service.domain"` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Runtime binary | `string` | `"python3.7"` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | Daemon Secret Manager | `string` | n/a | yes |
| <a name="input_service"></a> [service](#input\_service) | Autoscaling Group service name, e.g. 'bastion'. This will be prefix for DNS records. | `string` | n/a | yes |
| <a name="input_slack_webhook"></a> [slack\_webhook](#input\_slack\_webhook) | slack webhook for notifications | `string` | n/a | yes |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | Name for the SNS topic which will handle notifications of instance launch and terminate events | `string` | n/a | yes |
| <a name="input_ttl"></a> [ttl](#input\_ttl) | TTL value for the DNS record(s) | `number` | `60` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Id of a zone file to add records to | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | n/a |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | n/a |
| <a name="output_lambda_manage_dns_role_arn"></a> [lambda\_manage\_dns\_role\_arn](#output\_lambda\_manage\_dns\_role\_arn) | n/a |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | n/a |
<!-- END_TF_DOCS -->
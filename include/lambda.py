import boto3
import json
import os
import urllib3
import traceback
from string import Template

zone_id = os.environ['ZONE_ID']
service = os.environ['SERVICE']
ttl = int(os.environ['TTL'])
dns_role_arn = os.environ.get('DNS_ROLE_ARN')
webhook_url = os.environ['SLACK_WEBHOOK']
environment = os.environ['ENVIRONMENT']

private_instance_record_template = os.environ['PRIVATE_INSTANCE_RECORD_TEMPLATE']
private_asg_record_template = os.environ['PRIVATE_ASG_RECORD_TEMPLATE']
public_asg_record_template = os.environ['PUBLIC_ASG_RECORD_TEMPLATE']

manage_instance_dns = os.environ['MANAGE_INSTANCE_DNS'].lower() in ["true", "1"]
manage_private_asg_dns = os.environ['MANAGE_PRIVATE_ASG_DNS'].lower() in ["true", "1"]
manage_public_asg_dns = os.environ['MANAGE_PUBLIC_ASG_DNS'].lower() in ["true", "1"]

aws_region = os.environ.get('AWS_DEFAULT_REGION')

ec2_resource = boto3.resource('ec2', region_name=aws_region)
asg_client = boto3.client('autoscaling', region_name=aws_region)


def get_session(role_arn, sts_client):
    """
    Assumes a role in the given account and returns a Boto3 session.

    """

    # Assume the role and get back credentials.
    acc_id = sts_client.get_caller_identity()['Account']
    response = sts_client.assume_role(
        RoleArn=role_arn,
        RoleSessionName='{}-updates-in-{}-from-{}'.format(service, zone_id, acc_id),
        DurationSeconds=900,
    )
    creds = response['Credentials']

    # Return a new session using those credentials.
    session = boto3.Session(
        aws_access_key_id=creds['AccessKeyId'],
        aws_secret_access_key=creds['SecretAccessKey'],
        aws_session_token=creds['SessionToken'],
    )
    return session


def generate_record_name(template, **kwargs):
    """
    generate Resource Record name
    :param template: string
    :param kwargs: other arguments: service, az, instance_id, domain
    :return: string.Template
    """

    names_map = {
        'service.domain': Template('$service.$domain'),
        'service.az.domain': Template('$service.$az.$domain'),
        'service-az.domain': Template('$service-$az.$domain'),
        'service.az_short.domain': Template('$service.$az_short.$domain'),
        'service-az_short.domain': Template('$service-$az_short.$domain'),
        'service.instanceid.domain': Template('$service.$instance_id.$domain'),
        'service-instanceid.domain': Template('$service-$instance_id.$domain'),
        'service.internal.domain': Template('$service.internal.$domain'),
        'service.internal.region.domain': Template('$service.internal.$region.$domain'),
        'service-internal.domain': Template('$service-internal.$domain'),
        'service.region.domain': Template('$service.$region.$domain'),
        'service-region.domain': Template('$service-$region.$domain'),
    }

    return names_map[template].substitute(**kwargs)


def change_rrs(changes, zoneid, r53_client):
    """
    make DNS update
    :param changes: list of R53 changes
    :param zoneid: string
    :return: response dict
    """
    print('Performing change {}'.format(json.dumps(changes)))
    response = r53_client.change_resource_record_sets(
        HostedZoneId='/hostedzone/{}'.format(zoneid),
        ChangeBatch={
            'Comment': 'Updated by Lambda Function',
            'Changes': changes
        }
    )
    return response


def parse_event(event):
    """
    :param event: event object received by lambda
    :return: tuple containing message and metadata from an event object
    """
    metadata = {}
    message = json.loads(event['Records'][0]['Sns']['Message'])
    if 'NotificationMetadata' in list(message.keys()):
        metadata = json.loads(message['NotificationMetadata'])
    return message, metadata


def get_instance_metadata(instance_id):
    """
    :param instance_id: string
    :return: dict containing info about instance
    """

    instance = ec2_resource.Instance(instance_id)
    # we only want running instances
    if instance.state['Name'] not in ['running']:
        return False
    metadata = {
        'private_ip': instance.private_ip_address,
        'private_hostname': instance.private_dns_name,
        'public_ip': instance.public_ip_address,
        'az': instance.placement['AvailabilityZone']
    }
    return metadata


def get_asg_instances(asg_name, asg_event, message):
    """
    :param asg_name: string
    :return: dict of dicts with keys being instance IDs and values
    being instance information as returned by get_instance_metadata
    """
    asg = asg_client.describe_auto_scaling_groups(
        AutoScalingGroupNames=[asg_name])
    # get instances IDs
    asg_instances = [i['InstanceId']
                     for i in asg['AutoScalingGroups'][0]['Instances']]

    # ensure launching instance is found in the asg
    ec2_instance = ""
    if asg_event == "autoscaling:EC2_INSTANCE_LAUNCH":
        ec2_instance = message['EC2InstanceId']
        if ec2_instance not in asg_instances:
            raise Exception('Launched instance not found in asg')

    return_value = {}
    for instance in asg_instances:
        metadata = get_instance_metadata(instance)
        if metadata:
            return_value[instance] = metadata
        else:
            # ensure metadata is found for launching instance
            if instance == ec2_instance and asg_event == "autoscaling:EC2_INSTANCE_LAUNCH":
                raise Exception('No metadata returned for ' + instance)
    return return_value

def slack_notification(message):
    try:
        slack_message = {'text': message}

        http = urllib3.PoolManager()
        response = http.request('POST',
                                webhook_url,
                                body = json.dumps(slack_message),
                                headers = {'Content-Type': 'application/json'},
                                retries = False)
    except:
        traceback.print_exc()

    return True

def lambda_handler(event, context):

    # assume role in DNS account if dns_role_arn is specified
    if dns_role_arn:
        sts_client = boto3.client('sts')
        dns_session = get_session(dns_role_arn, sts_client)
        r53_client = dns_session.client('route53')
    else:
        r53_client = boto3.client('route53')

    # get domain name
    hostedzone = r53_client.get_hosted_zone(Id=zone_id)
    domain = hostedzone['HostedZone']['Name']

    # parse event
    message, metadata = parse_event(event)

    print('Received event: {}'.format(json.dumps(event)))
    print('Message: {}'.format(json.dumps(message)))
    print('Metadata: {}'.format(json.dumps(metadata)))

    # asg name and event
    asg_name = message['AutoScalingGroupName']
    asg_event = message['Event']

    # get metadata of all instances in ASG
    instances_metadata = get_asg_instances(asg_name, asg_event, message)
    print('ASG INSTANCES: {}'.format(json.dumps(instances_metadata)))

    # create a list of public addresses of all instances in ASG
    asg_public_ips = []
    for _metadata in instances_metadata.values():
        if _metadata['public_ip'] is not None:
            asg_public_ips.append(_metadata['public_ip'])
        else:
            continue
    print('ASG_PUBLIC_IPS: {}'.format(json.dumps(asg_public_ips)))

    # create a list of private addresses of asg instances
    asg_private_ips = [instances_metadata[i]['private_ip']
                       for i in instances_metadata.keys()]
    print('ASG_PRIVATE_IPS: {}'.format(json.dumps(asg_private_ips)))

    # holds DNS changes to do
    changes = []

    if manage_instance_dns:
        # instance has been launched or asg created
        if instances_metadata:
            for instance_id, instance_info in instances_metadata.items():
                instance_ip = instance_info['private_ip']
                az = instance_info['az']
                az_short = az.split('-')[-1]
                instance_record_name = generate_record_name(
                    private_instance_record_template,
                    az=az,
                    az_short=az_short,
                    region=aws_region,
                    domain=domain,
                    instance_id=instance_id,
                    service=service)

                instance_rrs = {
                    'Action': 'UPSERT',
                    'ResourceRecordSet': {
                        'Name': instance_record_name,
                        'Type': 'A',
                        'TTL': ttl,
                        'ResourceRecords': [{'Value': instance_ip}]
                    }
                }
                changes.append(instance_rrs)

    # do we have any public IP addresses?
    if manage_public_asg_dns and len(asg_public_ips) > 0:
        # public asg group record
        public_asg_record_name = generate_record_name(
            public_asg_record_template,
            domain=domain,
            region=aws_region,
            service=service)
        public_rrs = {
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': public_asg_record_name,
                'Type': 'A',
                'TTL': ttl,
                'ResourceRecords': [{'Value': pub_ip}
                                    for pub_ip in asg_public_ips]
            }
        }
        changes.append(public_rrs)

    #  do we have any private IPs ?
    if manage_private_asg_dns and len(asg_private_ips) > 0:
        # internal asg group record
        private_asg_record_name = generate_record_name(
            private_asg_record_template,
            domain=domain,
            region=aws_region,
            service=service)
        private_rrs = {
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': private_asg_record_name,
                'Type': 'A',
                'TTL': ttl,
                'ResourceRecords': [{'Value': priv_ip}
                                    for priv_ip in asg_private_ips]
            }
        }
        changes.append(private_rrs)

    # apply dns updates
    if changes:
        change_rrs(changes, zone_id, r53_client)

    slack_notification('Rundeck ' + ENVIRONMENT + 'has restarted!!')

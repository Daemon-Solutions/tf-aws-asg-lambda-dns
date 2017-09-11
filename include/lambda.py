#!/usr/bin/python

import boto3
import json
import os
from string import Template


zone_id = os.environ['ZONE_ID']
service = os.environ['SERVICE']

private_instance_record_template = os.environ['PRIVATE_INSTANCE_RECORD_TEMPLATE']
private_asg_record_template = os.environ['PRIVATE_ASG_RECORD_TEMPLATE']
public_asg_record_template = os.environ['PUBLIC_ASG_RECORD_TEMPLATE']

manage_instance_dns = os.environ['MANAGE_INSTANCE_DNS'].lower() in ["true", "1"]
manage_private_asg_dns = os.environ['MANAGE_PRIVATE_ASG_DNS'].lower() in ["true", "1"]
manage_public_asg_dns = os.environ['MANAGE_PUBLIC_ASG_DNS'].lower() in ["true", "1"]

aws_region = os.environ.get('AWS_DEFAULT_REGION')
r53_client = boto3.client('route53')
ec2_resource = boto3.resource('ec2', region_name=aws_region)
asg_client = boto3.client('autoscaling', region_name=aws_region)

# get domain name
try:
    hostedzone = r53_client.get_hosted_zone(Id=zone_id)
    domain = hostedzone['HostedZone']['Name']
except Exception as e:
    print e
    raise


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
        'service.instanceid.domain': Template('$service.$instance_id.$domain'),
        'service-instanceid.domain': Template('$service-$instance_id.$domain'),
        'service.internal.domain': Template('$service.internal.$domain'),
        'service-internal.domain': Template('$service-internal.$domain'),
        'service.region.domain': Template('$service.$region.$domain'),
        'service-region.domain': Template('$service-$region.$domain'),
    }

    return names_map[template].substitute(**kwargs)


def lambda_handler(event, context):

    message, metadata = parse_event(event)

    print 'Received event: {}'.format(json.dumps(event))
    print 'Message: {}'.format(json.dumps(message))
    print 'Metadata: {}'.format(json.dumps(metadata))

    # asg name
    asg_name = message['AutoScalingGroupName']

    # get metadata of all instances in ASG
    instances_metadata = get_asg_instances(asg_name)
    print 'ASG INSTANCES: {}'.format(json.dumps(instances_metadata))

    # create a list of public addresses of all instances in ASG
    asg_public_ips = []
    for _metadata in instances_metadata.itervalues():
        if _metadata['public_ip'] is not None:
            asg_public_ips.append(_metadata['public_ip'])
        else:
            continue
    print 'ASG_PUBLIC_IPS: {}'.format(json.dumps(asg_public_ips))

    # create a list of private addresses of asg instances
    asg_private_ips = [instances_metadata[i]['private_ip']
                       for i in instances_metadata.iterkeys()]
    print 'ASG_PRIVATE_IPS: {}'.format(json.dumps(asg_private_ips))

    # holds DNS changes to do
    changes = []
    asg_event_types = {
        'launch': 'autoscaling:EC2_INSTANCE_LAUNCH',
        'terminate': 'autoscaling:EC2_INSTANCE_TERMINATE',
        'test': 'autoscaling:TEST_NOTIFICATION',
    }

    def generated_record(template):
        return generate_record_name(template,
                                    az=az,
                                    region=aws_region,
                                    domain=domain,
                                    instance_id=instance_id,
                                    service=service
                )

    if manage_instance_dns:
        # instance has been launched or asg created
        if instances_metadata:
            for instance_id, instance_info in instances_metadata.iteritems():
                instance_ip = instance_info['private_ip']
                az = instance_info['az']
                instance_record_name = generated_record(private_instance_record_template)
                instance_rrs = {
                    'Action': 'UPSERT',
                    'ResourceRecordSet': {
                        'Name': instance_record_name,
                        'Type': 'A',
                        'TTL': 60,
                        'ResourceRecords': [{'Value': instance_ip}]
                    }
                }
                changes.append(instance_rrs)

    # do we have any public IP addresses?
    if manage_public_asg_dns and len(asg_public_ips) > 0:
        # public asg group record
        public_asg_record_name = generated_record(public_asg_record_template)
        public_rrs = {
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': public_asg_record_name,
                'Type': 'A',
                'TTL': 60,
                'ResourceRecords': [{'Value': pub_ip}
                                    for pub_ip in asg_public_ips]
            }
        }
        changes.append(public_rrs)

    #  do we have any private IPs ?
    if manage_private_asg_dns and len(asg_private_ips) > 0:
        # internal asg group record
        private_asg_record_name = generated_record(private_asg_record_template)
        private_rrs = {
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': private_asg_record_name,
                'Type': 'A',
                'TTL': 60,
                'ResourceRecords': [{'Value': priv_ip}
                                    for priv_ip in asg_private_ips]
            }
        }
        changes.append(private_rrs)

    # apply dns updates
    if changes:
        change_rrs(changes, zone_id)


# helpers

def find_record(name, zone_id):
    """
    find resource record
    :param name: string, record name to find
    :param zone_id: string
    :return: resource record:
        [{u'Name': 'myrecord.kops.askredhat.com.',
         u'ResourceRecords': [{u'Value': '10.10.10.10'},
         {u'Value': '10.10.10.11'},
         {u'Value': '10.10.10.12'}],
         u'TTL': 300,
         u'Type': 'A'}]
    """
    paginator = r53_client.get_paginator('list_resource_record_sets')
    page_iterator = paginator.paginate(
        HostedZoneId='hostedzone/{}'.format(zone_id))
    rrs = None
    for page in page_iterator:
        rrs = filter(lambda record:
                     record['Name'] == name, page['ResourceRecordSets'])
        if rrs:
            break
    return rrs


def change_rrs(changes, zoneid):
    """
    make DNS update
    :param changes: list of R53 changes
    :param zoneid: string
    :return: response dict
    """
    print 'Performing change {}'.format(json.dumps(changes))
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
    if 'NotificationMetadata' in message.keys():
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


def get_asg_instances(asg_name):
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
    return_value = {}
    for instance in asg_instances:
        metadata = get_instance_metadata(instance)
        if metadata:
            return_value[instance] = metadata
        else:
            continue
    return return_value

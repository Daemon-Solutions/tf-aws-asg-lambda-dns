#!/usr/bin/env python3

import boto3
import json
import sys

aws_region = sys.argv[1]
asg_name = sys.argv[2]
sns_topic_arn = sys.argv[3]


client = boto3.client('sns',region_name=aws_region)

message = json.dumps({
    'Event': 'autoscaling:TEST_NOTIFICATION',
    'AutoScalingGroupName': asg_name})

response = client.publish(
    TopicArn=sns_topic_arn,
    Message=message)

json.dump(response, sys.stdout)

package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/route53"
	tfaws "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/require"
)

// AsgInstanceInfo Contains info for ASG instances
type AsgInstanceInfo struct {
	InstanceID string
	PrivateIP  string
	PublicIP   string
	AZ         string
	AZShort    string
	Region     string
	Service    string
	Domain     string
}

// AzForEc2InstanceNotFound error when couldnt get AZ for EC2 instance
type AzForEc2InstanceNotFound struct {
	InstanceID string
	AwsRegion  string
}

// Gather info about ASG EC2 Instances in the given region
func getAsgInstancesInfo(t *testing.T, asgName string, awsRegion string, service string, domain string) []AsgInstanceInfo {
	instanceIds := tfaws.GetInstanceIdsForAsg(t, asgName, awsRegion)

	if len(instanceIds) == 0 {
		t.Fatalf("Could not find any instances in ASG %s in %s", asgName, awsRegion)
	}

	instances := []AsgInstanceInfo{}

	for _, instanceID := range instanceIds {
		az := getAvailabilityZoneOfEc2Instance(t, instanceID, awsRegion)
		azSplit := strings.Split(az, "-")
		azShort := azSplit[len(azSplit)-1]
		instances = append(
			instances,
			AsgInstanceInfo{
				InstanceID: instanceID,
				PrivateIP:  tfaws.GetPrivateIpOfEc2Instance(t, instanceID, awsRegion),
				PublicIP:   tfaws.GetPublicIpOfEc2Instance(t, instanceID, awsRegion),
				AZ:         az,
				AZShort:    azShort,
				Region:     awsRegion,
				Service:    service,
				Domain:     domain,
			},
		)
	}

	return instances
}

func getAvailabilityZoneOfEc2InstancesE(t *testing.T, instanceIDs []string, awsRegion string) (map[string]string, error) {
	client := tfaws.NewEc2Client(t, awsRegion)
	input := ec2.DescribeInstancesInput{InstanceIds: aws.StringSlice(instanceIDs)}
	output, err := client.DescribeInstances(&input)
	if err != nil {
		return nil, err
	}

	azs := map[string]string{}

	for _, reserveration := range output.Reservations {
		for _, instance := range reserveration.Instances {
			azs[aws.StringValue(instance.InstanceId)] = aws.StringValue(instance.Placement.AvailabilityZone)
		}
	}

	return azs, nil
}

func getAvailabilityZoneOfEc2Instances(t *testing.T, instanceIDs []string, awsRegion string) map[string]string {
	azs, err := getAvailabilityZoneOfEc2InstancesE(t, instanceIDs, awsRegion)
	require.NoError(t, err)
	return azs
}

func (err AzForEc2InstanceNotFound) Error() string {
	return fmt.Sprintf("Could not find an availability zone for EC2 Instance %s in %s", err.InstanceID, err.AwsRegion)
}

func getAvailabilityZoneOfEc2InstanceE(t *testing.T, instanceID string, awsRegion string) (string, error) {
	azs, err := getAvailabilityZoneOfEc2InstancesE(t, []string{instanceID}, awsRegion)
	if err != nil {
		return "", err
	}

	az, containsAZ := azs[instanceID]

	if !containsAZ {
		return "", AzForEc2InstanceNotFound{InstanceID: instanceID, AwsRegion: awsRegion}
	}

	return az, nil
}

func getAvailabilityZoneOfEc2Instance(t *testing.T, instanceID string, awsRegion string) string {
	az, err := getAvailabilityZoneOfEc2InstanceE(t, instanceID, awsRegion)
	require.NoError(t, err)
	return az
}

func buildResourceRecordSet(t *testing.T, name string, rtype string, ipAddresses []string, ttl int64) *route53.ResourceRecordSet {
	myRec := &route53.ResourceRecordSet{}
	myRec = myRec.SetName(name)
	rrs := []*route53.ResourceRecord{}
	for _, ip := range ipAddresses {
		rrs = append(rrs, &route53.ResourceRecord{Value: aws.String(ip)})
	}
	myRec = myRec.SetResourceRecords(rrs)
	myRec = myRec.SetTTL(ttl)
	myRec = myRec.SetType(rtype)

	return myRec
}

func getAllR53zoneRecordsE(t *testing.T, zoneID string, awsRegion string) ([]*route53.ResourceRecordSet, error) {
	r53client := NewR53Client(t, awsRegion)
	listParams := &route53.ListResourceRecordSetsInput{
		HostedZoneId: aws.String(zoneID),
	}
	respList, err := r53client.ListResourceRecordSets(listParams)

	if err != nil {
		fmt.Println(err.Error())
		return nil, err
	}

	return respList.ResourceRecordSets, nil
}

func getAllR53zoneRecords(t *testing.T, zoneID string, awsRegion string) []*route53.ResourceRecordSet {
	records, err := getAllR53zoneRecordsE(t, zoneID, awsRegion)
	require.NoError(t, err)
	return records
}

// NewR53Client creates a R53 client.
func NewR53Client(t *testing.T, awsRegion string) *route53.Route53 {
	client, err := NewR53ClientE(t, awsRegion)
	fmt.Println(client)
	require.NoError(t, err)
	return client
}

// NewR53ClientE creates an R53 client.
func NewR53ClientE(t *testing.T, awsRegion string) (*route53.Route53, error) {
	sess, err := tfaws.NewAuthenticatedSession(awsRegion)
	if err != nil {
		return nil, err
	}

	return route53.New(sess), nil
}

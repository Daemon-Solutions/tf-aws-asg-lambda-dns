package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/service/route53"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

// TestPrivateInstanceRecord runs test checking if private instance record is correctly created
func TestPrivateInstanceRecord(t *testing.T) {
	//t.Parallel()
	//awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	awsRegion := "eu-west-1"
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"aws_region":                       awsRegion,
			"manage_instance_dns":              "true",
			"private_instance_record_template": "service.az.domain",
			"ttl":                              60,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Get data from Terraform output
	domainName := terraform.OutputRequired(t, terraformOptions, "zone_name")
	zoneID := terraform.OutputRequired(t, terraformOptions, "zone_id")
	asgName := terraform.OutputRequired(t, terraformOptions, "asg_name")
	ttl := stringToInt(t, terraform.OutputRequired(t, terraformOptions, "ttl"))
	service := terraform.OutputRequired(t, terraformOptions, "service")

	// wait for instances to get provisioned
	aws.WaitForCapacity(t, asgName, awsRegion, 360, 1)

	// wait some time for lambda to kick in
	time.Sleep(20 * time.Second)

	instances := getAsgInstancesInfo(t, asgName, awsRegion)

	// get all records from the zone
	allResourceRecordSets := getAllR53zoneRecords(t, zoneID, awsRegion)
	logger.Logf(t, fmt.Sprintf("DNS RECORDS FOUND IN THE ZONE %s:", allResourceRecordSets))

	// for each instance check if the record match what it should
	var actualResourceRecordSet *route53.ResourceRecordSet

	for _, instance := range instances {

		expectedRecordName := fmt.Sprintf("%s.%s.%s", service, instance.AZ, domainName)
		ipAddress := []string{instance.PrivateIP}
		expectedResourceRecordSet := buildResourceRecordSet(t, expectedRecordName, "A", ipAddress, int64(ttl))

		for _, rrSet := range allResourceRecordSets {
			if *rrSet.Name == *expectedResourceRecordSet.Name {
				actualResourceRecordSet = rrSet
				break
			}
		}
		require.Equal(t, expectedResourceRecordSet, actualResourceRecordSet, "private_instance_record_template test failed")

	}
}

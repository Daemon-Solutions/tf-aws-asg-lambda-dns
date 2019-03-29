package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/service/route53"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

func TestRunPrivateInstanceRecord(t *testing.T) {
	//t.Parallel()
	//awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	awsRegion := "eu-west-1"

	templatesList := make([]string, 0, len(templatesMap))
	for k := range templatesMap {
		templatesList = append(templatesList, k)
	}

	examplesDir := test_structure.CopyTerraformFolderToTemp(t, repoRoot, "examples")

	defer test_structure.RunTestStage(t, "teardown", func() {
		teardownResources(t, examplesDir)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		terraformOptions := &terraform.Options{
			// The path to where our Terraform code is located
			TerraformDir: examplesDir,

			// Variables to pass to our Terraform code using -var options
			Vars: map[string]interface{}{
				"aws_region": awsRegion,
				"ttl":        60,
			},
		}
		// Apply terraform
		terraform.InitAndApply(t, terraformOptions)
		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)

		// Get data from Terraform output
		domainName := terraform.OutputRequired(t, terraformOptions, "zone_name")
		zoneID := terraform.OutputRequired(t, terraformOptions, "zone_id")
		ttl := stringToInt(t, terraform.OutputRequired(t, terraformOptions, "ttl"))
		service := terraform.OutputRequired(t, terraformOptions, "service")
		asgName := terraform.OutputRequired(t, terraformOptions, "asg_name")

		// wait for instances to get provisioned
		aws.WaitForCapacity(t, asgName, awsRegion, 360, 1)
		instances := getAsgInstancesInfo(t, asgName, awsRegion, service, domainName)

		for _, recordTemplate := range templatesList {
			privateInstanceRecordTest(t, recordTemplate, ttl, zoneID, instances, awsRegion, terraformOptions)
		}
	})
}

// privateInstanceRecordTest runs test checking if private instance record is correctly created
func privateInstanceRecordTest(t *testing.T, recordTemplate string, ttl int, zoneID string, instances []AsgInstanceInfo, awsRegion string, terraformOptions *terraform.Options) {

	logger.Logf(t, fmt.Sprintf("Checking %s:", recordTemplate))
	terraformOptions.Vars["manage_instance_dns"] = "true"
	terraformOptions.Vars["private_instance_record_template"] = recordTemplate
	terraform.InitAndApply(t, terraformOptions)

	//wait some time for lambda to kick in
	time.Sleep(20 * time.Second)

	// get all records from the zone
	allResourceRecordSets := getAllR53zoneRecords(t, zoneID, awsRegion)
	logger.Logf(t, fmt.Sprintf("DNS RECORDS FOUND IN THE ZONE %s:", allResourceRecordSets))

	// for each instance check if the record match what it should
	var actualResourceRecordSet *route53.ResourceRecordSet

	for _, instance := range instances {

		//		expectedRecordName := fmt.Sprintf("%s.%s.%s", service, instance.AZ, domainName)
		expectedRecordName := generateRecordTemplate(t, instance, recordTemplate)
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

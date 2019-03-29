package test

import (
	"bytes"
	"html/template"
	"strconv"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

const repoRoot = "../"

// add your new tempalate here to get it included in tests
var templatesMap = map[string]string{
	"service.domain":                 "{{.Service}}.{{.Domain}}",
	"service.az.domain":              "{{.Service}}.{{.AZ}}.{{.Domain}}",
	"service-az.domain":              "{{.Service}}-{{.AZ}}.{{.Domain}}",
	"service.az_short.domain":        "{{.Service}}.{{.AZShort}}.{{.Domain}}",
	"service-az_short.domain":        "{{.Service}}-{{.AZShort}}.{{.Domain}}",
	"service.instanceid.domain":      "{{.Service}}.{{.InstanceID}}.{{.Domain}}",
	"service-instanceid.domain":      "{{.Service}}-{{.InstanceID}}.{{.Domain}}",
	"service.internal.domain":        "{{.Service}}.internal.{{.Domain}}",
	"service.internal.region.domain": "{{.Service}}.internal.{{.Region}}.{{.Domain}}",
	"service-internal.domain":        "{{.Service}}-internal.{{.Domain}}",
	"service.region.domain":          "{{.Service}}.{{.Region}}.{{.Domain}}",
	"service-region.domain":          "{{.Service}}-{{.Region}}.{{.Domain}}",
}

func stringToIntE(t *testing.T, s string) (int, error) {
	i, err := strconv.Atoi(s)
	if err != nil {
		return 0, err
	}
	return i, err
}

func stringToInt(t *testing.T, s string) int {
	i, err := stringToIntE(t, s)
	require.NoError(t, err)
	return i
}

func teardownResources(t *testing.T, examplesDir string) {
	terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
	terraform.Destroy(t, terraformOptions)
}

func generateRecordTemplate(t *testing.T, templateData AsgInstanceInfo, templateString string) string {
	var result bytes.Buffer
	tmpl := template.New(templateString)
	tmpl, _ = tmpl.Parse(templatesMap[templateString])
	tmpl.Execute(&result, templateData)
	return result.String()
}

package test

import (
  "regexp"
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/stretchr/testify/assert"
)

func TestTerraformOpenSearchExample(t *testing.T) {
  t.Parallel()

  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
  TerraformDir: "../examples/opensearch",
  VarFiles: []string{"terraform.tfvars"},
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

  // verify that the domain_id   
  domainID := terraform.Output(t, terraformOptions, "domain_id")
  assert.NotEmpty(t, domainID)

  domainIDRegx := `^(\d+)\/([\w\-]+)$`
  domainIDRegxMatch, err := regexp.MatchString(domainIDRegx, domainID)
  assert.Nil(t, err, "Error during ARN validation with regex")
  assert.True(t, domainIDRegxMatch, "domain_arn should follow expected format (using regex)")

  // verify domain_arn
  domainArn := terraform.Output(t, terraformOptions, "domain_arn")
  assert.NotEmpty(t, domainArn)

  domainArnRegex := `^arn:aws:es:[a-z0-9-]+:\d{12}:domain/[a-zA-Z0-9-]+$`
  matchArn, err := regexp.MatchString(domainArnRegex, domainArn)
  assert.Nil(t, err, "Error during ARN validation with regex")
  assert.True(t, matchArn, "domain_arn should follow expected format (using regex)")

  // verify domain_dashboard_endpoint
  domainDashboardEndpoint := terraform.Output(t, terraformOptions, "domain_dashboard_endpoint")
  domainDashboardEndpointRegex := `^vpc-(.+?)-([a-zA-Z0-9]+)\.us-east-1\.es\.amazonaws\.com/_dashboards$`
  domainDashboardEndpointRegexMatch, err := regexp.MatchString(domainDashboardEndpointRegex, domainDashboardEndpoint)
  assert.Nil(t, err, "Error during domain_dashboard_endpoint validation with regex")
  assert.True(t, domainDashboardEndpointRegexMatch, "domain_dashboard_endpoint should follow expected format (using regex)")

  // verify domain_endpoint
  domainEndpoint:= terraform.Output(t, terraformOptions, "domain_endpoint")
  assert.NotEmpty(t, domainEndpoint)

  domainEndpointRegx := `^vpc-(.+?)-([a-zA-Z0-9]{26})\.us-east-1\.es\.amazonaws\.com$`
  domainEndpointRegxMatch, err := regexp.MatchString(domainEndpointRegx, domainEndpoint)
  assert.Nil(t, err, "Error during domain_endpoint validation with regex")
  assert.True(t, domainEndpointRegxMatch, "domain_endpoint should follow expected format (using regex)")
}
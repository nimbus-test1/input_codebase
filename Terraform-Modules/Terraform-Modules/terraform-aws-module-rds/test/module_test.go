package test

import (
  "testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformRDSExample(t *testing.T) {
  t.Parallel()

  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
  TerraformDir: "../examples/rds",
  VarFiles: []string{"terraform.tfvars"},
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

  // validate instance engine
  outputEngine := terraform.Output(t, terraformOptions, "db_instance_engine")
  expectedValue := "mysql"
  assert.Equal(t, expectedValue, outputEngine)

  //validate instance identifier
  outputIdentifier := terraform.Output(t, terraformOptions, "db_instance_identifier")
  expectedValue = "mysql-db-01"
  assert.Equal(t, expectedValue, outputIdentifier)

  //validate instance port
  outputPort := terraform.Output(t, terraformOptions, "db_instance_port")
  expectedValue = "3306"
  assert.Equal(t, expectedValue, outputPort)
}
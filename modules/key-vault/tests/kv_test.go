package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestAzureKeyVault(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	kvName := terraform.Output(t, terraformOptions, "key_vault_name")
	assert.NotEmpty(t, kvName, "Key Vault Name should not be empty")

	kvId := terraform.Output(t, terraformOptions, "key_vault_id")
	assert.NotEmpty(t, kvId, "Key Vault ID should not be empty")
}

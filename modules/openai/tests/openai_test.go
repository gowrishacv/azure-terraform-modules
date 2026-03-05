package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestAzureOpenAI(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	openaiName := terraform.Output(t, terraformOptions, "openai_name")
	assert.NotEmpty(t, openaiName, "OpenAI Name should not be empty")

	openaiEndpoint := terraform.Output(t, terraformOptions, "openai_endpoint")
	assert.NotEmpty(t, openaiEndpoint, "OpenAI Endpoint should not be empty")
}

# ci-actions-iac


## GCP Module Testing Pipeline

`./github/workflow/moduleTestingWorkflowGCP.yml`


This is the intended pipeline for GCP module testing. It integrates with:
- Terraform validate and scan
  - Static code check and custom security policy scanning
- Terratest
  - Integration test that creates resources in GCP, runs predefined test cases to verify module functionality, and cleans up resources after test finishes

![alt text](terratest_pipeline.png)

Inputs:
- TF_STATE_FILE_IDENTIFIER:
  - A unique identifier for this resource as the state file name
- WORK_DIR:
  - path to the TF source code

Example Usage:

Ex: terraform-gcp-module-gcs: [Link](https://github.com/test-cloud-foundations-org/terraform-gcp-module-gcs)
`.github/workflows/gcs-module-testing.yml`

```
name: Use IaC Workflow
on:
  push:
    branches:
      - dev
jobs:
  simple_bucket_module:
    uses: testevops-org/ci-actions-iac/.github/workflows/moduleTestingWorkflowGCP.yml@feature/iac-testing-2
    secrets: inherit
    with:
      TF_STATE_FILE_IDENTIFIER: "gcs_simple_bucket"
      WORK_DIR: "examples/simple_bucket"
```

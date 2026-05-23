# Resume CloudFront (Terraform)

This project provisions AWS infrastructure to host a PDF resume privately in S3 and deliver it securely through CloudFront.

## What this creates

- A unique S3 bucket (with random suffix)
- S3 public access block (all public access blocked)
- S3 versioning enabled
- Upload of your resume PDF to S3
- CloudFront Origin Access Control (OAC)
- CloudFront distribution serving the PDF over HTTPS
- S3 bucket policy allowing only this CloudFront distribution to read objects

## Architecture

```text
+-------------------+            HTTPS            +-----------------------------+
|      Viewer       | --------------------------> | CloudFront Distribution     |
| (Browser / User)  |                             | (default cert, GET/HEAD)    |
+-------------------+                             +--------------+--------------+
                                                                 |
                                                                 | SigV4 via OAC
                                                                 v
                                                  +--------------+--------------+
                                                  | S3 Bucket (private)          |
                                                  | - Public access blocked      |
                                                  | - Versioning enabled         |
                                                  | - Stores resume PDF          |
                                                  +-----------------------------+
```

## Project files

- `main.tf`: all resources and policies
- `variables.tf`: configurable inputs
- `outputs.tf`: useful deployment outputs

## Prerequisites

- Terraform `>= 1.5.0`
- AWS account + credentials configured (for example via AWS CLI profile/environment variables)
- Access to create S3, CloudFront, IAM policy, and related resources

## Usage

Initialize and deploy:

```bash
terraform init
terraform plan
terraform apply
```

After apply, Terraform outputs:

- `bucket_name`
- `cloudfront_domain_name`
- `resume_url`

Open `resume_url` in your browser to access the file through CloudFront.

## Configuration

Default variables (from `variables.tf`):

- `aws_region` (default: `us-east-1`)
- `bucket_name_prefix` (default: `resume-site`)
- `resume_object_key` (default: `rafael_cv_052026.pdf`)
- `resume_file_path` (default: `rafael_cv_052026.pdf`)

Override via CLI:

```bash
terraform apply \
  -var="aws_region=us-east-1" \
  -var="bucket_name_prefix=my-resume-site" \
  -var="resume_object_key=resume.pdf" \
  -var="resume_file_path=./resume.pdf"
```

Or create a `terraform.tfvars` file:

```hcl
aws_region         = "us-east-1"
bucket_name_prefix = "my-resume-site"
resume_object_key  = "resume.pdf"
resume_file_path   = "./resume.pdf"
```

## GitHub Actions deployment (OIDC assume role)

This repository includes `.github/workflows/deploy.yml` to run Terraform in GitHub Actions using AWS OIDC.

### 1) Create AWS OIDC federated provider for GitHub

You must create this once per AWS account:

- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

### 2) Create IAM role for GitHub Actions

Use the trust policy in `policies/github-oidc-trust-policy.json` and replace `<AWS_ACCOUNT_ID>`.

`token.actions.githubusercontent.com:sub` is set to:

- `repo:rafaelhueb92/cloudfront-bucket-resume:ref:refs/heads/main`

This means only workflows running from branch `main` can assume the role.

Attach `policies/terraform-deploy-permissions-policy.json` to that role.

### 3) Configure GitHub repository settings

- Secret: `AWS_ROLE_TO_ASSUME` = IAM role ARN
- Variable: `TF_STATE_BUCKET` = existing S3 bucket for Terraform remote state

The workflow runs:

- `terraform init` with backend S3 config from `TF_STATE_BUCKET`
- `terraform validate`
- `terraform plan`
- `terraform apply`

### 4) Terraform remote state

Remote state is configured in `main.tf` using `backend "s3" {}` and is initialized in CI with:

- bucket: `${{ vars.TF_STATE_BUCKET }}`
- key: `resume-cloudfront/terraform.tfstate`
- region: `${{ env.AWS_REGION }}`

The state bucket must already exist before CI runs.

## Update resume file

Replace your local PDF and run:

```bash
terraform apply
```

The `aws_s3_object` resource uses `filemd5(...)`, so Terraform detects file content changes and uploads the updated file.

## Destroy resources

```bash
terraform destroy
```

## Notes

- The S3 bucket is not publicly accessible.
- Access is granted to CloudFront only through a bucket policy tied to the distribution ARN.
- CloudFront uses the default certificate and serves over HTTPS.

# Day 3 — Terraform S3 bucket notes

This document explains each line/block in `day3/main.tf` and provides comprehensive Terraform commands and best-practices for managing an AWS S3 bucket with Terraform.

References:

- <https://developer.hashicorp.com/terraform/docs>
- <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket>

---

## File: `day3/main.tf` (explanation)

1-9: terraform { required_providers }

- Declares provider requirements. `aws` provider is sourced from `hashicorp/aws` and constrained with `version = "~> 6.0"` which means any version >= 6.0.0 and < 7.0.0. This pins major version to prevent breaking changes while allowing minor/patch updates.

11-15: (blank / comments)

- Comments starting with `#` are ignored by Terraform; use them to annotate your configuration.

17-24: resource "aws_s3_bucket" "first_bucket" { ... }

- `resource` declares a managed AWS S3 bucket with local name `first_bucket`.
- `bucket = "my-tf-test-bucket-12345654321"` sets the globally unique S3 bucket name. Bucket names must follow AWS rules (lowercase, numbers, hyphens, 3-63 chars, no underscores or uppercase, cannot look like an IP address).
- `tags = { Name = "my bucket" Environment = "Dev" }` attaches tags to the bucket, useful for cost allocation and resource identification.

Note: Many optional and recommended arguments for `aws_s3_bucket` are not present here — see below for recommended additions (encryption, block public access, versioning, lifecycle rules, logging, force_destroy, etc.).

---

## Recommended `aws_s3_bucket` settings (explanations)

- `acl` — canned ACL like `private`. Avoid public ACLs unless explicitly required.
- `force_destroy = true|false` — when `true` Terraform will delete all objects (including versions) when destroying the bucket. Useful for dev, dangerous in production.
- `versioning { enabled = true }` — enable object versioning to prevent accidental data loss.
- `server_side_encryption_configuration` — require SSE (SSE-S3 or SSE-KMS). Example with KMS:

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
        kms_master_key_id = "arn:aws:kms:..."
      }
    }
  }

- `lifecycle_rule` — lifecycle policies to expire/transition objects to S3 Glacier/IA.
- `logging { target_bucket = "..." target_prefix = "logs/" }` — access logging to another bucket.
- `block_public_acls = true`, `block_public_policy = true`, `restrict_public_buckets = true` — often configured via `aws_s3_bucket_public_access_block` resource to prevent public exposure.
- `website { index_document = "index.html" }` — for static website hosting.
- `replication_configuration` — for cross-region replication (requires roles and source/destination setup).

---

## Example enhanced S3 resource (snippet)

```hcl
resource "aws_s3_bucket" "first_bucket" {
  bucket = "my-tf-test-bucket-12345654321"
  acl    = "private"

  tags = {
    Name        = "my bucket"
    Environment = "Dev"
  }

  versioning {
    enabled = true
  }

  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.first_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}
```

---

## Terraform commands — what they do and examples

1) `terraform init`

- Initializes the working directory: downloads provider plugins, prepares backend (if configured), and creates `.terraform/` directory.

```bash
terraform init
```

1) `terraform validate`

- Checks configuration syntax and internal consistency (no external API calls). Good quick check before planning.

```bash
terraform validate
```

1) `terraform plan`

- Generates an execution plan showing actions Terraform will perform.
- `-out=planfile` saves the plan for later `apply`.

```bash
terraform plan -out=tfplan
```

1) `terraform apply` (interactive)

- Applies changes; prompts for approval.

```bash
terraform apply
```

1) `terraform apply -auto-approve`

- Applies changes without waiting for user confirmation (use with caution, CI-friendly).

```bash
terraform apply -auto-approve
terraform apply tfplan          # apply a previously saved plan
terraform apply tfplan -auto-approve
```

1) `terraform plan -destroy` / `terraform destroy`

- Show or perform destroy actions.

```bash
terraform plan -destroy -out=destroyplan
terraform apply destroyplan
# or directly
terraform destroy -auto-approve
```

1) `terraform fmt`

- Formats Terraform files to standard style.

```bash
terraform fmt -recursive
```

1) `terraform show` and `terraform show -json`

- Inspect a saved plan or state.

```bash
terraform show tfplan
terraform show -json tfplan > plan.json
```

1) State commands

- `terraform state list` — list tracked resources
- `terraform state show <address>` — show a resource in state
- `terraform import <address> <id>` — import an existing resource into state

1) Workspace and backends

- Configure remote backends (S3 remote state with DynamoDB lock) for team collaboration. See provider docs for `backend "s3"`.

---

## Common flags and CI usage

- `-auto-approve` — skip interactive approval (use in automation only).
- `-input=false` — prevent prompts for input (use in CI).
- `-var 'key=value'` — pass variables on the CLI.

Example CI-friendly flow:

```bash
terraform init -input=false
terraform plan -out=tfplan -input=false
terraform apply -input=false -auto-approve tfplan
```

---

## Lifecycle and deletion safety

- By default, destroying a bucket with objects will fail unless `force_destroy = true` or objects are removed first.
- For production, prefer lifecycle rules and manual object cleanup rather than `force_destroy = true`.

---

## Security & permissions

- Ensure the IAM principal running Terraform has permissions for S3, KMS (if used), IAM roles (for replication), and S3 logging.
- Prefer least-privilege policies that allow only necessary actions like `s3:CreateBucket`, `s3:PutBucketVersioning`, `s3:PutEncryptionConfiguration`, `s3:PutBucketPolicy`, etc.

---

## Troubleshooting quick tips

- "BucketAlreadyOwnedByYou" — bucket exists in AWS account; import into state using `terraform import`.
- Naming errors — verify bucket name constraints (only lowercase letters, numbers, dots and hyphens with restrictions).
- Destroy failing due to objects — enable `force_destroy` or empty bucket before destroy.

---

## Next steps (suggested)

- Add `aws_s3_bucket_public_access_block` to block public access.
- Add `versioning` and `server_side_encryption_configuration` for durability and encryption.
- Configure a remote backend for state (S3 + DynamoDB lock).

---

## Terraform state

- What is state:
  - Terraform state is a snapshot of the infrastructure that Terraform manages. It maps resources in configuration to real-world objects and stores metadata used by Terraform to create/update/destroy resources.

- Local vs remote state:
  - Local state: stored in a `terraform.tfstate` file in the working directory. Simple but not suitable for teams.
  - Remote state (recommended for teams): stored in a remote backend such as S3, Azure Blob Storage, or HashiCorp Consul. Remote backends support locking and access control.

- Common remote backend for AWS teams:
  - Backend: S3 for storing the state object + DynamoDB for state locking to prevent concurrent writes.

- Example `backend` block (S3 + DynamoDB):

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "project-name/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

- Initialize or reconfigure backend:

```bash
terraform init                   # initial init will set up the backend
terraform init -reconfigure      # reconfigure backend settings
terraform init -backend-config="path/to/backend.hcl"
```

- State commands and use cases:
  - `terraform state list` — list resources tracked in state
  - `terraform state show <address>` — show attributes for a tracked resource
  - `terraform state pull` — download the raw state file
  - `terraform state push <path>` — push a state file to the backend (advanced; use sparingly)
  - `terraform state mv <from> <to>` — move/rename resources in state
  - `terraform state rm <address>` — remove an item from state (resource left in cloud)
  - `terraform import <address> <id>` — import an existing resource into state
  - `terraform state replace-provider` — update provider addresses in state when upgrading provider source

Examples:

```bash
terraform state list
terraform state show aws_s3_bucket.first_bucket
terraform import aws_s3_bucket.first_bucket my-tf-test-bucket-12345654321
terraform state mv aws_s3_bucket.old aws_s3_bucket.new
```

- State locking and concurrency:
  - Use DynamoDB or a backend that supports locking to avoid concurrent `apply` operations corrupting state.
  - Ensure CI pipelines obtain locks by using the configured backend; do not run parallel `terraform apply` that share the same state key.

- Security and best practices:
  - Keep sensitive values out of state when possible; treat state as sensitive: it may contain secrets (e.g., DB passwords, ARNs).
  - Encrypt state at rest (S3 `encrypt = true`) and enforce access via IAM.
  - Enable S3 bucket versioning for state bucket to allow rollback of accidental state corruption.
  - Restrict who can access or modify the remote state via IAM policies.

- Backing up and recovery:
  - With S3 versioning enabled, you can recover an earlier state file if needed.
  - Use `terraform state pull` to obtain a local copy for inspection.

- Migrating local state to a remote backend:
  1. Configure the `backend` block in your configuration.
  2. Run `terraform init` and follow prompts to migrate state to the backend.

```bash
terraform init
```

---

If you want, I can add an example `backend.hcl` and a small README describing how to create the S3 bucket and DynamoDB table for locking.

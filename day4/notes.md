# Day 4 — Detailed notes: S3 backend for Terraform state and locking

This file documents every relevant detail for the S3 backend configuration shown below and provides examples, best practices, IAM policies, Terraform snippets to create the backend bootstrap resources (S3 + DynamoDB), and commands to initialize, migrate, and operate state safely.

Example backend config (user-provided):

```hcl
backend "s3" {
  bucket = "my-tf-state-bucket-12345654321"
  key    = "dev/terraform.tfstate"
  region = "ap-south-1"
  encrypt = true
  lock_table = "tf-state-lock"
}
```

IMPORTANT: The official backend option for state locking is `dynamodb_table` (not `lock_table`). If you see `lock_table` in configs, replace it with `dynamodb_table = "tf-state-lock"`. Also `use_lockfile` is not a standard backend option — you may be thinking of the `.terraform.lock.hcl` dependency lockfile (different concept). This notes file uses the correct backend keys and shows both correct and common mistakes.

---

## Backend settings explained (field-by-field)

- `bucket` (required):
  - The name of the S3 bucket that will store the Terraform state file. Bucket name must be globally unique in AWS and follow S3 naming rules.
  - Example: `my-terraform-state-bucket-prod`.

- `key` (required):
  - The path within the S3 bucket where the state file will be stored. Treat this as a file path (object key). For workspaces or environments, include a prefix (e.g., `envs/dev/terraform.tfstate`) or include `workspace_key_prefix`.
  - Example: `dev/terraform.tfstate` stores the state at `s3://bucket/dev/terraform.tfstate`.

- `region` (required for some SDKs):
  - The AWS region where the S3 bucket exists. Use the provider region or the bucket's region. Example: `ap-south-1`.

- `encrypt` (optional, boolean):
  - When `true` Terraform will request S3 to store the object encrypted at rest using the S3-managed encryption (SSE-S3). For more control or KMS, use `kms_key_id`.
  - Example: `encrypt = true`.

- `dynamodb_table` (optional but recommended for locking):
  - Name of a DynamoDB table used for state locking. Terraform will perform conditional writes to this table to obtain a lock before modifying state. This prevents concurrent `apply` operations from corrupting state.
  - Example: `dynamodb_table = "terraform-locks"`.

- `kms_key_id` (optional):
  - ARN or ID of a KMS key to encrypt the state file with AWS KMS.

- `acl`, `endpoint`, `force_path_style`, `role_arn`, `workspace_key_prefix`, etc. — see Terraform docs for additional backend parameters.

---

## Common mistakes and clarifications

- `lock_table` is not a documented backend option. Use `dynamodb_table`.
- `use_lockfile` is not a backend option. The `.terraform.lock.hcl` file is a dependency lockfile managed by `terraform init` and provider plugin resolution; it is unrelated to state locking.
- Always enable a locking backend (DynamoDB) for team workflows that share state.

---

## How the S3 backend + DynamoDB locking works (high level)

1. Before performing state-changing operations, Terraform will attempt to acquire a lock by writing a lock entry to the DynamoDB table.
2. If the lock is acquired, Terraform proceeds and updates the state file in S3.
3. After the operation completes (success or failure), Terraform releases the lock by deleting or updating the DynamoDB entry.
4. If another process holds the lock, Terraform will retry until timeout (or fail depending on CLI flags).

This prevents race conditions and state corruption when multiple operators or CI jobs act on the same state concurrently.

---

## Example correct backend block (recommended)

```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state-bucket-12345654321"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "tf-state-lock"
    # Optional: workspace_key_prefix = "myproject/"
  }
}
```

---

## Bootstrap resources — create the S3 bucket and DynamoDB table (Terraform snippet)

Create these resources in a small separate project (bootstrap) or manually via the AWS console. Keep bootstrap project minimal because the backend cannot use resources created in the same apply that configures the backend — create backend first.

```hcl
provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "tf_state_bucket" {
  bucket = "my-tf-state-bucket-12345654321"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = {
    Name = "terraform-state-bucket"
    Env  = "infra"
  }
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = "tf-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-lock-table"
  }
}
```

Notes:

- Enable S3 `versioning` on the state bucket so you can recover previous state if needed.
- Use SSE and optionally a KMS key to protect state contents.

---

## Minimal IAM policy for Terraform to manage state

Attach a policy to the IAM role/user used by Terraform that allows S3 and DynamoDB operations required for state and locking. This example is narrow-scoped to the bucket and table resources (replace ARNs with your values):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning"
      ],
      "Resource": [
        "arn:aws:s3:::my-tf-state-bucket-12345654321",
        "arn:aws:s3:::my-tf-state-bucket-12345654321/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:ap-south-1:123456789012:table/tf-state-lock"
    }
  ]
}
```

Also allow `kms:Encrypt`/`Decrypt` if you use a KMS key for state encryption.

---

## Initialization and migration commands

1. Create the backend resources (S3 bucket & DynamoDB table) first (via console or a bootstrap Terraform run).
2. Configure backend in your main config (the `terraform { backend "s3" { ... } }` block).
3. Run:

```bash
terraform init
```

- On first run, Terraform will offer to migrate your local state to the backend if local state exists.
- To reconfigure or force migration:

```bash
terraform init -reconfigure
terraform init -backend-config=backend.hcl
```

- To automate and avoid interactive prompts (CI), use `-input=false` and `-no-color` as needed.

---

## Working with workspaces and key naming

- The `key` is the single state file path for the configuration. To support multiple environments (dev/stage/prod) or multiple workspaces, either:
  - Use separate `key` values per environment (e.g., `dev/terraform.tfstate`, `prod/terraform.tfstate`), or
  - Use `workspace_key_prefix` setting to have Terraform include workspace names in the state path automatically.

Example with `workspace_key_prefix`:

```hcl
backend "s3" {
  bucket               = "my-tf-state-bucket-12345654321"
  key                  = "terraform.tfstate"
  region               = "ap-south-1"
  dynamodb_table       = "tf-state-lock"
  workspace_key_prefix = "myproject/"
}
```

This will store state at `myproject/<workspace>/terraform.tfstate`.

---

## Troubleshooting & common errors

- "AccessDenied": check S3 and DynamoDB IAM permissions.
- "BucketNotFound": verify the `bucket` exists in the specified region.
- "BucketAlreadyOwnedByYou": if the bucket exists, import or reuse it rather than trying to create a new one with same name.
- DynamoDB locking errors: ensure the `dynamodb_table` exists and the IAM identity has read/write permissions.
- If `terraform init` fails to migrate state, run with `-reconfigure` and inspect the `.terraform` directory and logs.

---

## Best practices summary

- Use a dedicated S3 bucket for Terraform state with versioning enabled.
- Enable server-side encryption (SSE or KMS) for the state file.
- Use DynamoDB table for state locking to prevent concurrent writes.
- Keep backend configuration out of version control when storing secrets or sensitive backend-specific settings — instead use `backend.hcl` and `terraform init -backend-config=backend.hcl` in CI.
- Limit IAM permissions to the minimum required for state operations.
- Use clear `key` naming and `workspace_key_prefix` for multi-environment projects.

---

## Optional: `backend.hcl` example (external config file)

Create a `backend.hcl` file and do not check it into source control if it contains sensitive details (role ARNs, etc.). Example:

```hcl
bucket         = "my-tf-state-bucket-12345654321"
key            = "dev/terraform.tfstate"
region         = "ap-south-1"
dynamodb_table = "tf-state-lock"
encrypt        = true
```

Initialize with:

```bash
terraform init -backend-config=backend.hcl
```

---

If you'd like, I can:

- Add a `bootstrap/` Terraform project that creates the S3 bucket and DynamoDB table with proper IAM policies, or
- Generate `backend.hcl` and a short README with one-click steps to create the backend resources in the console.

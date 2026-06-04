# Day6 — Terraform notes and modularity guide

## Overview of this folder

- Purpose: deploy a simple set of AWS resources and use an S3 backend for remote state.
- Files present:
  - `providers.tf` — Terraform settings and AWS provider configuration.
  - `backend.tf` — Remote state backend (S3) configuration.
  - `variables.tf` — Declares input variables used by the root module.
  - `locals.tf` — Local values derived from variables.
  - `main.tf` — Resource definitions (S3 bucket, VPC, EC2 instance).
  - `outputs.tf` — Exposes created resource IDs from the root module.

## What each file does (details)

- `providers.tf`
  - Locks required provider (aws) in `terraform { required_providers { ... } }`.
  - Declares `provider "aws" { region = "ap-south-1" }` used by the root module.
  - Best practice: keep provider blocks in a dedicated file like this so settings are easy to find.

- `backend.tf`
  - Configures remote state storage using `backend "s3"` with `bucket`, `key`, `region`, and locking options.
  - Remote state prevents local state drift and enables collaboration.
  - Note: after adding/changing backend you must run `terraform init` to configure it.

- `variables.tf`
  - Declares `var.enviornment` and `var.region` with defaults.
  - Suggestion: fix the typo `enviornment` → `environment` to avoid confusion across modules.
  - Use `terraform.tfvars` or environment variables to override defaults for different environments.

- `locals.tf`
  - Builds derived names like `bucket_name`, `vpc_name`, `ec2_name` using `var.enviornment`.
  - Locals are useful to centralize naming conventions and avoid repeating expressions.

- `main.tf`
  - Contains resource blocks for `aws_s3_bucket.first_bucket`, `aws_vpc.sample`, and `aws_instance.example`.
  - Each resource uses `var.region`, `var.enviornment` and names from `local.*`.
  - For larger projects split resource definitions into multiple files (e.g., `s3.tf`, `network.tf`, `compute.tf`). HCL merges all `*.tf` files in a directory into a single module.

- `outputs.tf`
  - Exposes the IDs of created resources via outputs: `ec2_id`, `bucket_id`, `vpc_id`.
  - Outputs are used for human-readable info and for wiring modules together.

## How Terraform organizes configuration across files

- Terraform treats all `.tf` files in a directory as a single module namespace. Splitting into multiple files is purely for human organization.
- Common split pattern at the root module:
  - `providers.tf` — provider and version constraints
  - `backend.tf` — remote state
  - `variables.tf` — input variables
  - `locals.tf` — local computations
  - `main.tf` or `resources.tf` — resources
  - `outputs.tf` — exported outputs
  - `versions.tf` — provider/terraform required_version (optional)
- You can create as many `*.tf` files as you like; Terraform will load and merge them.

## Modularity: when and why to extract modules

- Use modules to encapsulate logically-related resources (for example: networking, s3 buckets, ec2 autoscaling, RDS).
- Benefits:
  - Reuse: call same module with different inputs for dev/prod/qa.
  - Encapsulation: groups variables, resources, and outputs into a single unit.
  - Readability: keeps the root module small and focused on composition.
- Module types:
  - Local modules: `./modules/<name>` inside the repository.
  - Published modules: hosted on the Registry or Git.

## Example: extract S3 bucket into a local module

Structure:

```
day6/
  main.tf          # root calls modules
  variables.tf
  providers.tf
  backend.tf
  outputs.tf
  modules/
    s3/
      main.tf
      variables.tf
      outputs.tf
```

Root module usage (in `main.tf` of root):

```
module "s3_bucket" {
  source = "./modules/s3"
  bucket_name = local.bucket_name
  region = var.region
}
```

Module `modules/s3/main.tf`:

```
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  acl    = var.acl
  tags   = var.tags
}
```

Module `modules/s3/variables.tf`:

```
variable "bucket_name" { type = string }
variable "acl" { type = string default = "private" }
variable "tags" { type = map(string) default = {} }
```

Module `modules/s3/outputs.tf`:

```
output "bucket_id" { value = aws_s3_bucket.this.id }
output "bucket_arn" { value = aws_s3_bucket.this.arn }
```

- Callers get outputs via `module.s3_bucket.bucket_id`.
- Keep provider configuration at root. If a module needs to use a different provider alias, pass `provider = aws.some_alias` explicitly when calling the module.

## Passing values and using outputs

- Root module sets variables and locals and passes them into modules.
- Example: `module.network` can output `vpc_id`, and root or other modules can reference `module.network.vpc_id`.
- For cross-repository or cross-directory references, use `terraform_remote_state` (data source) or published module outputs. Remote state should be treated as a data source only — avoid writing into another module's state.

## Naming conventions and small tips

- Keep variable names short and consistent across modules (e.g., `environment`, `region`). Avoid typos.
- Use `locals` for derived names and to keep templates consistent.
- Use `terraform.tfvars` (never commit secrets) or environment variables for sensitive values.
- Use `.tfvars.example` to show required variables (safe to commit).
- Use `terraform fmt` to keep consistent formatting.

## Commands you will use

- Initialize: `terraform init` (use after changing backend or providers)
- Validate: `terraform validate` (quick syntactic check)
- Plan: `terraform plan -var-file="terraform.tfvars"`
- Apply: `terraform apply -var-file="terraform.tfvars"`
- Format: `terraform fmt -recursive`
- Show remote state: `terraform state list` (after init and selecting workspace)

## Recommended improvements for this directory

- Fix the variable name typo: rename `enviornment` → `environment` and update all references.
- Split `main.tf` into `s3.tf`, `network.tf`, `compute.tf` when more resources are added.
- Create a `modules/` folder and move grouped resources (e.g., S3) into local modules.
- Add a `versions.tf` with `terraform { required_version = ">= 1.0.0" }` to pin Terraform core version.
- Add a `.gitignore` entry to ignore local `terraform.tfstate` and crash logs; commit `terraform.tfvars.example` but not `terraform.tfvars`.

## Example: splitting resource files without modules

- Simply create `s3.tf`, `vpc.tf`, `ec2.tf` next to `variables.tf`. Terraform will evaluate them together — this is just an organizational change, not modularization.

## Example: module call for environment-specific deployment

```
# root variables.tf
variable "environment" { default = "dev" }
variable "region" { default = "ap-south-1" }

# root main.tf
module "network" { source = "./modules/network" environment = var.environment region = var.region }
module "app" { source = "./modules/app" environment = var.environment region = var.region }
```

## Resources for learning

- Terraform docs: <https://www.terraform.io/docs>
- Module best practices: <https://www.terraform.io/docs/language/modules/develop>

---
If you want, I can:

- Update the variable typo and create a `terraform.tfvars.example` for this folder.
- Extract the S3 bucket into a local module and show a tested example.
- Run `terraform fmt` and `terraform validate` here (I can run commands if you want).

Created file: [day6/notes.md](day6/notes.md)

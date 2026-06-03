# Day 2 — Terraform notes for `main.tf`

This file explains each block/line of `main.tf` in this folder and lists common Terraform commands and the use of provider `version`.

Source references:

- <https://developer.hashicorp.com/terraform/docs>
- <https://registry.terraform.io/providers/hashicorp/aws/latest/docs>

---

## File: day2/main.tf (line-by-line)

1-7: terraform {

- `required_providers` declares provider requirements for this configuration.
- `aws = { source = "hashicorp/aws" version = "~> 6.0" }` tells Terraform to use the AWS provider from the HashiCorp registry and constrain the provider version to the 6.x series (compatible updates allowed, but not 7.0+). Using a version constraint helps ensure reproducible behavior across environments.

9-12: provider "aws" {

- This block configures the AWS provider. Here `region = "ap-south-1"` sets the default AWS region for API calls.
- Other provider settings (credentials, endpoints, profile) can be set here or via environment variables.

14-18: resource "aws_vpc" "example" {

- `resource` declares a managed resource. The type is `aws_vpc` and the local name is `example`.
- `cidr_block = "10.0.0.0/16"` sets the VPC IPv4 network range.
- After `terraform apply`, Terraform will create an AWS VPC with that CIDR and track it in the state as `aws_vpc.example`.

---

## Notes on dedicated hosts (optional / if present)

- The `aws_ec2_host` resource (not present in the current `main.tf`) requires an `availability_zone` argument and expects properties related to EC2 dedicated hosts, not VPC IDs. If you add an `aws_ec2_host` resource, see the provider docs: <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_host>.

---

## Common Terraform commands (what they do + examples)

- `terraform init`
  - Initializes a working directory: downloads provider plugins, sets up the backend (if configured), and prepares the working directory for other commands.
  - Example:

```bash
terraform init
```

- `terraform validate`
  - Validates the configuration files in a directory for syntactic correctness and internal consistency (no external API calls). Useful before `plan`.

```bash
terraform validate
```

- `terraform plan`
  - Creates an execution plan showing what actions Terraform will take to reach the desired state. Does not change any real resources.

```bash
terraform plan -out=tfplan
```

- `terraform apply`
  - Applies the changes required to reach the desired state. Can accept a saved plan (`terraform apply tfplan`) or create one interactively.

```bash
terraform apply tfplan
```

- `terraform fmt`
  - Formats Terraform code to canonical style.

```bash
terraform fmt
```

- `terraform destroy`
  - Destroys all resources managed by the configuration in the current workspace.

```bash
terraform destroy
```

---

## Provider `version` usage and best practices

- Pin provider versions using constraints (for example, `~> 6.0`) to avoid unexpected breaking changes from major upgrades.
- Use semantic version constraints:
  - `= 6.2.0` — exact version
  - `~> 6.0` — any 6.x version (>=6.0.0 and <7.0.0)
  - `>= 6.0, < 7.0` — explicit range
- When upgrading a provider, test in a separate environment or workspace and run `terraform plan` to inspect changes before applying.

---

## Quick troubleshooting

- Missing required argument errors: check the resource docs to ensure all required arguments are present.
- Unsupported argument errors: confirm the resource type accepts that argument; some fields belong on related resources instead.

---

If you want, I can:

- Add inline links to the exact lines in `main.tf`.
- Expand the notes to include examples for creating subnets, security groups, and EC2 instances.
- Run `terraform init` and `terraform validate` here and paste the output.

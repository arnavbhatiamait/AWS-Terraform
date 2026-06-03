# Day 5 — Terraform variables and precedence (detailed notes)

This note explains all common variable types and sources in Terraform, the typical precedence used when multiple sources provide a value, practical examples, and how to inspect or override values in workflows.

References:

- <https://developer.hashicorp.com/terraform/docs>

---

## Variable sources (what can set a variable)

- Variable `default` inside a `variable` block in a module.
- `terraform.tfvars` or `terraform.tfvars.json` files loaded automatically by Terraform.
- `*.auto.tfvars` or `*.auto.tfvars.json` files (automatically loaded when present).
- Environment variables named `TF_VAR_<variable_name>` (for example `TF_VAR_environment`).
- Command-line flags `-var 'name=value'` or `-var-file=FILE` (e.g., `terraform plan -var='environment=prod'`).

Note: The exact order of evaluation is documented by HashiCorp; the practical and safe rule is: CLI flags > environment variables > tfvars files > default values. Use CLI flags for temporary overrides (CI), TF_VAR_* for environment-specific quick overrides, and tfvars files for persistent environment configuration.

---

## Recommended precedence (highest → lowest)

1. Command line `-var` and `-var-file` (highest precedence)
2. Environment variables `TF_VAR_<name>`
3. `*.auto.tfvars` and `*.auto.tfvars.json`
4. `terraform.tfvars` and `terraform.tfvars.json`
5. `variable` block `default` value (lowest)

Practical notes:

- Use `-var` for one-off overrides or CI pipelines.
- Use `TF_VAR_` when exporting values in a shell or in automation where you don't want to keep a file.
- Use `terraform.tfvars` or `env-specific` `*.tfvars` files to store environment configuration under version control (avoid secrets).
- Use `*.auto.tfvars` for files you want automatically loaded but still committed (e.g., common overrides). Check your repo policy before committing.

---

## Common pitfalls and gotchas

- Typo in environment variable name: `TF_VAR_enviornment` (misspelled) will not populate `var.environment`. Ensure the variable name matches exactly.
- `terraform.tfvars` is loaded automatically, but if you pass `-var` or `-var-file` they will override tfvars values.
- Sensitive data: values in state can contain sensitive data — avoid putting secrets into tfvars checked into source control. Use a secrets manager or environment variables in CI with secure storage.

---

## Examples — files and commands

1) `variable` block example (declare in `variables.tf` or `main.tf`):

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment name"
  default     = "dev"
}
```

1) `terraform.tfvars` (automatic file):

```hcl
# day5/terraform.tfvars
environment = "preprod"
```

1) `prod.tfvars` (environment-specific file):

```hcl
environment = "prod"
```

1) Exporting environment variable (shell):

```bash
# correct spelling
export TF_VAR_environment=stage
# incorrect (won't be used):
export TF_VAR_enviornment=stage
```

1) CLI override (highest precedence):

```bash
terraform plan -var="environment=pred"
# (typo in value above: pred) correct would be:
terraform plan -var="environment=prod"
```

1) Use `-var-file` to load a specific file:

```bash
terraform plan -var-file=prod.tfvars
```

1) Example CI-friendly flow (non-interactive):

```bash
terraform init -input=false
terraform plan -var-file=ci.tfvars -out=tfplan -input=false
terraform apply -input=false -auto-approve tfplan
```

---

## Inspecting variable values at runtime

- `terraform plan` will show computed values in the plan (unless the value is `sensitive`).
- `terraform console` can evaluate expressions and inspect variables in an interactive REPL after `terraform init`.
- You can create a temporary `output` to show the value (for debugging only; don't output secrets):

```hcl
output "debug_environment" {
  value = var.environment
  description = "Debug: shows resolved environment value"
}
```

Then run:

```bash
terraform apply -auto-approve
terraform output debug_environment
```

Or use `terraform plan` to preview the output without applying by using `-out` and `terraform show`.

---

## Variable types, validation, and sensitive flag

- Primitive types: `string`, `number`, `bool`.
- Collection types: `list(<type>)`, `map(<type>)`, `set(<type>)`, `object({ ... })`, `tuple([ ... ])`.

Example with validation and sensitive:

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"

  validation {
    condition     = contains(["dev","stage","prod","preprod"], var.environment)
    error_message = "environment must be one of dev, stage, preprod, prod"
  }
}

variable "db_password" {
  type      = string
  sensitive = true
}
```

- `sensitive = true` prevents the value from being shown in plan output and from being displayed by `terraform output` unless explicitly requested.

---

## Demonstration: precedence behavior

Given these sources:

- `variable "environment" { default = "dev" }`
- `terraform.tfvars` contains `environment = "preprod"`
- Environment: `export TF_VAR_environment=stage`
- CLI: `terraform plan -var='environment=prod'`

Resolved order (what Terraform will use): CLI `prod` (highest), then environment `stage`, then `terraform.tfvars` `preprod`, then variable default `dev` (lowest). So the plan will use `prod`.

If you accidentally export `TF_VAR_enviornment=stage` (typo), Terraform will ignore it and continue to use `terraform.tfvars` (`preprod`) unless overridden by CLI.

---

## `terraform output` and `tf output` usage

- `terraform output` reads outputs from the current state. Use after `terraform apply` or with `terraform show` on a saved plan.
- In your shell you ran `tf output` which likely is an alias or script; the canonical command is `terraform output`.

Examples:

```bash
terraform apply -auto-approve
terraform output
terraform output some_output_name
```

To read outputs from a specific state file (without changing working directory), use `terraform output -state=path/to/terraform.tfstate`.

---

## Best practices

- Avoid committing secrets in `*.tfvars` under version control.
- Prefer environment-specific `*.tfvars` files (e.g., `dev.tfvars`, `prod.tfvars`) and pass them with `-var-file` during CI.
- Prefer the `-var` flag for temporary overrides and `TF_VAR_` for quick shell overrides.
- Add `validation` blocks for inputs with restricted allowed values.
- Use `sensitive = true` for secrets and do not create outputs that reveal them.

---

If you want, I can:

- Add a small `variables.tf` and `main.tf` example in `day5/` demonstrating the precedence with a scripted sequence and `README.md` showing exact commands to reproduce the precedence behaviour.
- Fix the misspelled `TF_VAR_enviornment` in your `terraform.tfvars` and show how to standardize variable naming.

---

## Locals (local values)

- Purpose:
  - `locals` define expressions evaluated within a module to compute reusable values derived from variables, constants, or other expressions. They are computed at plan time and are not part of state.

- Example:

```hcl
locals {
  project = "myproject"
  env_tag = upper(var.environment)
  bucket_name = "${local.project}-${var.environment}-bucket"
}
```

- Notes:
  - Locals help avoid repeating expressions and make configs easier to read and maintain.
  - They are not input variables; you cannot set them from the CLI or `tfvars`.

## Outputs

- Purpose:
  - `output` blocks expose values from a module or root configuration for humans, other modules, or automation. Outputs are stored in state and can be retrieved with `terraform output`.

- Example:

```hcl
output "bucket_name" {
  value       = aws_s3_bucket.first_bucket.bucket
  description = "The S3 bucket name created for this environment"
}

output "api_endpoint" {
  value     = module.api.endpoint
  sensitive = true
}
```

- `sensitive = true` prevents the value from being displayed in plan/apply outputs and `terraform output` by default.

## Accessing outputs

- CLI (human-friendly):

```bash
terraform output                # lists non-sensitive outputs
terraform output bucket_name    # prints a single output value
terraform output -json > outputs.json   # machine-readable JSON
```

- From a saved state file (local):

```bash
terraform output -state=path/to/terraform.tfstate
```

- In automation (parse JSON):

```bash
terraform output -json | jq -r '.bucket_name.value'
```

- From another Terraform configuration (module):
  - Use `module.<name>.<output>` to reference outputs exported by a child module.
  - Example: `module.network.vpc_id`.

- Cross-workspace / Cross-repo access:
  - Use the `terraform_remote_state` data source to read outputs from another state backend.

Example `terraform_remote_state` using S3 backend:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "my-tf-state-bucket-12345654321"
    key    = "network/terraform.tfstate"
    region = "ap-south-1"
  }
}

resource "aws_instance" "example" {
  subnet_id = data.terraform_remote_state.network.outputs.private_subnet_id
  # ...
}
```

## Inspecting outputs without applying

- Use `terraform plan -out=tfplan` then `terraform show -json tfplan` to inspect computed values in the plan (note: some values remain unknown until apply).

```bash
terraform plan -out=tfplan
terraform show -json tfplan | jq '.planned_values.root_module.resources[]'
```

## Summary and best practices for locals & outputs

- Use `locals` to centralize computed values and avoid repetition.
- Keep outputs focused: expose only what downstream modules or operators need.
- Mark secrets as `sensitive = true` and avoid writing secrets to stdout in automation.
- Use `terraform output -json` in CI to consume outputs programmatically.

# Terraform Variable Types — Reference and Examples

This note describes Terraform variable types, how to declare them, pass values, validate them, and common usage patterns.

## Overview
Terraform variables allow you to parameterize your configuration. Each variable can have a `type`, `default`, `description`, `sensitive` flag, and optional `validation` rules.

Supported types fall into these categories:
- Primitive: `string`, `number`, `bool`
- Collection: `list(<type>)`, `set(<type>)`, `map(<type>)`
- Complex: `object({ ... })`, `tuple([ ... ])`
- Generic: `any`

Note: Terraform performs strong type checking. If a provided value doesn't match the declared type, `terraform plan` will error.

---
## Primitive types

- string
  - Example:
    ```hcl
    variable "app_name" {
      type        = string
      description = "Application name"
      default     = "my-app"
    }
    ```
- number
  - Example:
    ```hcl
    variable "instance_count" {
      type        = number
      description = "Number of instances to create"
      default     = 1
    }
    ```
- bool
  - Example:
    ```hcl
    variable "enable_feature_x" {
      type        = bool
      description = "Toggle feature X"
      default     = false
    }
    ```

---
## Collection types

- list(<type>)
  - Ordered sequence, can contain duplicates.
  - Example:
    ```hcl
    variable "availability_zones" {
      type    = list(string)
      default = ["ap-south-1a", "ap-south-1b"]
    }
    ```
- set(<type>)
  - Unordered collection, unique elements.
  - Example:
    ```hcl
    variable "allowed_ports" {
      type    = set(number)
      default = [80, 443]
    }
    ```
- map(<type>)
  - Key/value mapping; keys are strings.
  - Example:
    ```hcl
    variable "tags" {
      type = map(string)
      default = {
        Owner = "team-a"
        Env   = "dev"
      }
    }
    ```

---
## Complex types

- object({ ... })
  - Structured type with named attributes and their own types.
  - Useful for passing structured configuration into modules.
  - Example:
    ```hcl
    variable "db_config" {
      type = object({
        engine   = string
        version  = string
        replicas = number
      })
      default = {
        engine   = "postgres"
        version  = "13"
        replicas = 1
      }
    }
    ```
  - Access: `var.db_config.engine`

- tuple([ ... ])
  - Heterogeneous, fixed-length ordered collection where each position has a specified type.
  - Example:
    ```hcl
    variable "endpoint" {
      type = tuple([string, number])
      default = ["10.0.0.5", 8080]
    }
    ```
  - Access: `var.endpoint[0]` (string), `var.endpoint[1]` (number)

---
## Generic type: `any`
- `any` accepts any value. Useful when you want flexibility but lose static type validation.
- Example:
  ```hcl
  variable "extra_settings" {
    type = any
  }
  ```
- Common pattern: use `any` for inputs that might be maps, lists, or single values depending on use case, and then normalize with `tolist()`, `tomap()`, or `jsondecode()`.

---
## Optional attributes and nullability
- Terraform variables may accept `null` for optional values. You can combine `object` attributes with `optional()` (Terraform 1.4+) to indicate optional object attributes.
- Example (object with optional attribute):
  ```hcl
  variable "app" {
    type = object({
      name    = string
      port    = optional(number)
    })
    default = { name = "demo" }
  }
  ```
- If `null` is allowed, you can declare a variable without a default and pass `null` explicitly.

---
## Validation blocks
- Use `validation` inside a variable to enforce custom rules.
- Example:
  ```hcl
  variable "instance_count" {
    type    = number
    default = 1

    validation {
      condition     = var.instance_count >= 1 && var.instance_count <= 10
      error_message = "instance_count must be between 1 and 10"
    }
  }
  ```

---
## Sensitive variables
- Mark `sensitive = true` so Terraform redacts values from CLI and logs.
- Example:
  ```hcl
  variable "db_password" {
    type      = string
    sensitive = true
  }
  ```
- Note: marking a variable `sensitive` does not encrypt it in state; use secret backends (Vault, SSM) or pass via environment in CI.

---
## How to pass values
- `terraform.tfvars` or `*.tfvars` files (auto-loaded)
- CLI: `terraform apply -var='name=value'` or `-var-file=custom.tfvars`
- Environment variable: `TF_VAR_<variable_name>` (e.g., `TF_VAR_app_name=my-app`)
- Modules: pass variables when calling a module: `module "m" { source = "./modules/m" name = var.app_name }`

Precedence (highest → lowest):
1. CLI `-var` and `-var-file` explicit flags
2. Environment variables `TF_VAR_*`
3. `terraform.tfvars` and `*.auto.tfvars` files
4. Variable default in code

---
## Examples: variables.tf and terraform.tfvars
- `variables.tf`:
  ```hcl
  variable "environment" { type = string }
  variable "region" { type = string, default = "ap-south-1" }
  variable "allowed_ips" { type = list(string) }
  variable "settings" { type = map(any), default = {} }
  ```
- `terraform.tfvars`:
  ```hcl
  environment = "prod"
  allowed_ips = ["1.2.3.4/32"]
  settings = { feature_x = true }
  ```

---
## Module inputs and outputs
- When designing modules, declare a clear `variables.tf` with types and defaults, and expose only necessary outputs.
- Example module call:
  ```hcl
  module "webapp" {
    source      = "./modules/webapp"
    name        = "my-app"
    instance_count = var.instance_count
  }

  output "webapp_id" { value = module.webapp.id }
  ```

---
## Common pitfalls and tips
- Typo in variable names breaks references; be consistent (`environment` vs `env`).
- Type mismatch: lists vs tuples vs sets — choose the right collection type.
- `map(string)` vs `map(any)` — prefer specific types when possible.
- When passing complex JSON from environment or CI, use `jsonencode()`/`jsondecode()` as needed.
- Keep secrets out of `*.tfvars` in version control.
- Use `validation` blocks to fail early with helpful messages.

---
## Quick reference examples
- Required string (no default):
  ```hcl
  variable "project" { type = string }
  ```
- Map of strings with default:
  ```hcl
  variable "tags" { type = map(string); default = { Owner = "team" } }
  ```
- Object input to modules:
  ```hcl
  variable "site" {
    type = object({ name = string, domain = string })
  }
  ```

---
If you want, I can:
- Add example `variables.tf` files for `day6` and `day7` showing each type in practice.
- Extract and fix the `enviornment` typo across the repo.

Created file: [variables-types.md](variables-types.md)

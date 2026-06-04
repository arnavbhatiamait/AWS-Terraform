# Terraform Meta-Arguments — Day09 Reference and Examples

This document explains the Terraform meta-arguments used in the Day 09 examples (and related patterns). Each section explains what the meta-argument does, when to use it, pitfalls, and includes a compact example (adapted from Day 09 code).

Note: meta-arguments are evaluated by the Terraform language (HCL) and apply to resources, modules, and sometimes data sources. They alter how Terraform creates, updates, and destroys resources, or how resource instances are mapped.

---

**depends_on**
- Purpose: create an explicit dependency between resources or between modules when Terraform cannot infer it from expressions.
- When to use: when a resource's lifecycle must wait for a side-effect or external resource that is not referenced by attributes.
- Caveat: Terraform usually tracks implicit dependencies through interpolations; use `depends_on` only when needed.

Example — ensure `aws_lambda_permission` is created after an S3 bucket (explicit dependency):
```hcl
resource "aws_s3_bucket" "code_bucket" {
  bucket = "my-code-bucket-${var.environment}"
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "s3.amazonaws.com"

  # Force explicit dependency on the S3 bucket for a side-effect (e.g., bucket policy attachment)
  depends_on = [aws_s3_bucket.code_bucket]
}
```

---

**count**
- Purpose: create N copies of a resource or module where instances are indexed by `count.index`.
- When to use: create a fixed number of homogeneous instances when ordering or positional access is desired.
- Caveat: `count` produces numeric-indexed instances; removing or reordering items can trigger replacements.

Example — create 3 EC2 instances:
```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  tags = {
    Name = "web-${count.index}"
  }
}
# Refer: aws_instance.web[0], aws_instance.web[1]
```

---

**for_each**
- Purpose: iterate over a set/map to create one resource per element; instances are keyed by the element (string or tuple).
- When to use: create resources from a collection (map or set) and maintain stable identity when collection elements are added/removed.
- Caveat: `for_each` requires the collection elements to be unique when used with sets/lists; maps preserve keys as instance keys.

Example — create multiple S3 buckets from a map of names:
```hcl
variable "bucket_names" {
  type = map(string)
}

resource "aws_s3_bucket" "app_buckets" {
  for_each = var.bucket_names
  bucket   = "${each.value}-${var.environment}"

  tags = {
    Name = each.value
  }
}
# Refer: aws_s3_bucket.app_buckets["keyname"].id
```

---

**provider (meta-argument)**
- Purpose: instruct a module or resource to use a specific provider or provider alias.
- When to use: multi-account, multi-region, or when a module needs a different provider configuration than the root.
- Example: create provider aliases in the root and reference them in a module/resource.

Root provider setup with alias:
```hcl
provider "aws" {
  region = "ap-south-1"
}

provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}
```
Use a provider alias for a resource/module:
```hcl
resource "aws_s3_bucket" "cross_region" {
  provider = aws.us_east
  bucket   = "cross-region-bucket-${var.environment}"
}

module "remote_network" {
  source   = "./modules/network"
  providers = { aws = aws.us_east }
}
```

---

**lifecycle (meta-argument)**
- Purpose: group of rules that control create/replace/destroy behavior and allow pre/post validation.
- Common sub-arguments used in Day 09 examples:
  - `create_before_destroy`
  - `prevent_destroy`
  - `ignore_changes`
  - `precondition` and `postcondition`
  - `replace_triggered_by`

General note: `lifecycle { ... }` is placed inside a resource or data block.

Sub-arguments:

- create_before_destroy
  - Create a replacement resource before destroying the current one (helps zero-downtime updates).
  - Example: recreate an S3 bucket or EC2 instance with replacement semantics.
  ```hcl
  lifecycle { create_before_destroy = true }
  ```
  - Caveat: not all resources support this semantics (e.g., some resources have constraints like unique names).

- prevent_destroy
  - Prevent accidental destruction; Terraform errors if a plan tries to destroy the resource.
  - Use-case: critical production data stores.
  ```hcl
  lifecycle { prevent_destroy = true }
  ```
  - To delete the resource you must remove the flag and apply again.

- ignore_changes
  - Instruct Terraform to ignore changes to specified attributes and not attempt to revert external/managed changes.
  - Useful when AWS or external systems change attributes (auto-scaling groups, ACLs).
  ```hcl
  lifecycle { ignore_changes = [desired_capacity, #other_attr] }
  ```
  - Use carefully: ignoring important fields can hide drift.

- precondition
  - Validate a condition before creation/update; if false, Terraform fails with `error_message` before applying.
  - Example from Day 09 ensuring allowed region:
  ```hcl
  lifecycle {
    precondition {
      condition     = contains(var.allowed_regions, data.aws_region.current.name)
      error_message = "ERROR: This resource can only be created in allowed regions"
    }
  }
  ```

- postcondition
  - Validate a condition after resource creation; helpful for compliance checks (e.g., required tags present).
  - Example from Day 09 ensuring required tags exist:
  ```hcl
  lifecycle {
    postcondition {
      condition     = contains(keys(self.tags), "Compliance")
      error_message = "ERROR: Bucket must have a 'Compliance' tag for audit purposes!"
    }
  }
  ```
  - `self` refers to the planned resource attributes.

- replace_triggered_by
  - Force replacement of this resource when the specified expressions change (usually referencing other resources).
  - Common use: recreate EC2 instances when a security group or launch template changes.
  ```hcl
  lifecycle {
    replace_triggered_by = [aws_security_group.app_sg.id]
  }
  ```
  - This is safer than `depends_on` for triggering replacement semantics.

---

Examples combined (compact pattern from Day 09)
```hcl
resource "aws_instance" "app_with_sg" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [aws_security_group.app_sg.id]
    ignore_changes        = ["tags.Demo"]
  }
}
```

---

**Practical tips and gotchas**
- Prefer `for_each` over `count` when creating resources from maps so instance identity is stable across changes.
- Use `provider` aliases when you manage multiple regions/accounts; pass providers into modules explicitly.
- Use `prevent_destroy` sparingly; it can block legitimate changes and CI/CD workflows.
- `precondition` and `postcondition` are for policy-level checks; keep error messages actionable.
- Avoid `depends_on` as a replacement for proper data or attribute references; prefer explicit references when possible.

---

If you'd like, I can:
- Apply these patterns to refactor `day9` into small modules demonstrating each meta-argument
- Add unit tests / `terraform validate` scripts to the lesson folder

Created file: [day9/meta-arguments.md](day9/meta-arguments.md)

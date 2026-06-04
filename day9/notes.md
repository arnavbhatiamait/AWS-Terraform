# Day 09 — Detailed Notes

This file documents the full contents of the `day9` directory, explains how each file works together, and deep-dives into the Terraform meta-arguments and patterns used in the examples. It includes actionable suggestions and next steps for improvement.

Files in this folder

- `providers.tf` — provider configuration and required provider constraints.
- `backend.tf` — S3 remote state backend.
- `variables.tf` — all input variables used in the examples (primitive/complex types).
- `main.tf` — resources and data sources demonstrating lifecycle rules, for_each/count patterns, and other examples.
- `outputs.tf` — currently commented outputs; used to export resource attributes.
- `tf_lifeCycleRules.png` — visual diagram illustrating lifecycle rules.

## Summary of `providers.tf`

- Locks the `hashicorp/aws` provider to `~> 6.0` and configures a default provider with `region = "ap-south-1"`.
- Best practice: pin provider version and optionally add `required_version` for Terraform core in a `versions.tf` file.

## Summary of `backend.tf`

- Configures an S3 backend with `bucket = "my-tf-state-bucket-123456543210"` and key `dev/terraform.tfstate`.
- Remote state is encrypted and uses `use_lockfile = true` for state locking (recommended for collaboration).
- After changing backend, run `terraform init`.

## Variables (`variables.tf`) — key points

- `enviornment` (typo) — string default `dev`. Recommendation: rename to `environment`.
- `region` — default `ap-south-1`.
- `instance_count` — number, default 1.
- `monitoring_enabled`, `associate_public_ip` — bools.
- `cidr_block` — list(string) with several example CIDRs (note: these are multiple CIDRs rather than single VPC CIDR; consider naming clarification).
- `allowed_vms` — list(string) of allowed instance types.
- `allowed_regions` — set(string) of allowed regions (used in preconditions in lesson files).
- `tags` — map(string) default with Environment, name, created_by (note: `name` uses `=` inside map, but that's okay in HCL? It's valid though unusual style)
- `ingress_values` — tuple([number, number, string]) for ingress rules.
- `config` — object with `region`, `instance_count`, `monitoring` demonstrating object usage.
- `bucket_names` & `bucket_names_set` — list and set of bucket names demonstrating `for_each` and unique collections.

### Variable type takeaways

- `list` preserves order and allows duplicates.
- `set` enforces uniqueness and is unordered; good for `for_each` where stable keys are not needed.
- `map` used for tags and keyed configs.
- `object` and `tuple` demonstrate structured inputs.

## Main resources (`main.tf`) — walkthrough

- Data sources:
  - `data.aws_ami.amazon_linux_2` — finds the latest Amazon Linux 2 AMI.
  - `data.aws_region.current` — current region (used in lifecycle conditions).
  - `data.aws_availability_zones.available` — fetches AZs.

- `aws_launch_template.app_server` — launch template used by Auto Scaling Group. Uses `var.allowed_vms[0]` to pick an instance type and tags via `merge(var.tags, { Name=..., Demo=... })`.

- `aws_instance example` — (note resource declaration is `resource aws_instance example{` which lacks quotes and uses a non-standard name; HCL typically requires `resource "aws_instance" "example" {`.)
  - Uses `ami`, `instance_type`, `region=tolist(var.allowed_regions)[0]`, `monitoring`, `tags` and a `lifecycle` block with `create_before_destroy = true`.
  - Comments explain `create_before_destroy` and `prevent_destroy`.

- `aws_autoscaling_group.app_servers` — demonstrates `lifecycle { ignore_changes = [desired_capacity] }` so Terraform doesn't revert external scaling changes.

- `aws_security_group.app_sg` — standard SG with ingress/egress and tag `Demo = "replace_triggered_by"`.

- `aws_instance.app_with_sg` — instance referencing the security group; likely intended to show `replace_triggered_by` in a lifecycle block (but lifecycle not present here; it's shown in other examples).

- `aws_s3_bucket.compliance_bucket` — bucket demonstrating `lifecycle { postcondition { condition = contains(keys(self.tags), "Compliance") } ... }` to validate tags after creation.

## Issues & quick fixes found

- Typo: `enviornment` should be `environment`. Update `variables.tf` and all references in `main.tf` to match.
- Invalid resource syntax: `resource aws_instance example{` should be `resource "aws_instance" "example" {`. Fix to avoid Terraform parse errors.
- Some resource blocks lack `lifecycle` options that comments reference (e.g., `replace_triggered_by` is explained but not applied to `aws_instance.app_with_sg`). Consider adding `lifecycle { replace_triggered_by = [aws_security_group.app_sg.id] }`.
- `cidr_block` variable is a list of CIDRs; if the intention is a single VPC CIDR, change type to `string` or rename variable to `cidr_blocks`.
- `outputs.tf` is commented out; add useful outputs (instance IDs, bucket ARNs) for module integration.

## Meta-arguments used in these examples (summary)

- `lifecycle` with `create_before_destroy`, `prevent_destroy`, `ignore_changes`, `precondition` and `postcondition`, `replace_triggered_by`.
- `for_each` (used implicitly in bucket creation examples across lesson files) and `count` mentioned in comments.
- `provider` aliasing is not used here but recommended for multi-region demos.
- `depends_on` is not used in these files but discussed in lesson materials.

See: [day9/meta-arguments.md](day9/meta-arguments.md) for a standalone reference with examples.

## Suggested edits and enhancements (actionable)

1. Fix parsing errors and typos:
   - Replace `enviornment` → `environment` across files.
   - Fix `resource aws_instance example{` to correct HCL syntax.
2. Add `versions.tf` with Terraform core version requirement:

   ```hcl
   terraform {
     required_version = ">= 1.4.0"
   }
   ```

3. Add concrete `outputs.tf` outputs for resources created in `main.tf`.
4. Extract reusable pieces into `modules/` (e.g., `modules/network`, `modules/compute`, `modules/s3`) with clear `variables.tf` and `outputs.tf`.
5. Add `terraform.tfvars.example` to show how to set `environment`, `allowed_vms`, and `bucket_names`.
6. Run `terraform fmt` and `terraform validate` after fixing syntactic issues.

## Commands to test locally

```bash
cd day9
terraform init
terraform validate
terraform plan -var-file="terraform.tfvars"  # if you create a tfvars
terraform apply
```

## Learning notes

- This lesson demonstrates Terraform lifecycle rules for production safety and zero-downtime updates.
- `precondition` and `postcondition` are powerful for enforcing policies but should be used with clear error messages.
- Prefer `for_each` for creating resources from collections of names/keys to preserve identity.

---
Created file: [day9/notes.md](day9/notes.md)

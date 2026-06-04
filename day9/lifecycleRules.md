# Terraform Lifecycle Rules in AWS

## Overview

Terraform provides the `lifecycle` meta-argument to control how resources are created, updated, and destroyed. Lifecycle rules help prevent downtime, avoid accidental deletion, enforce compliance, and manage external changes gracefully.

---

# 1. create_before_destroy

## Purpose

Creates a replacement resource before destroying the existing one.

This helps avoid downtime during infrastructure updates.

## Example

```hcl
resource "aws_instance" "example" {
  ami           = "ami-03f4878755434977f"
  instance_type = var.allowed_vms[0]

  lifecycle {
    create_before_destroy = true
  }
}
```

## Use Cases

* EC2 instance replacement
* Load balancer migration
* Database upgrades
* Production workloads requiring high availability

## Benefits

✅ Zero or minimal downtime

✅ Safer infrastructure updates

## Considerations

* Requires sufficient AWS quotas
* Temporary increase in resource costs

---

# 2. prevent_destroy

## Purpose

Prevents Terraform from accidentally deleting a resource.

## Example

```hcl
resource "aws_instance" "example" {
  ami           = "ami-03f4878755434977f"
  instance_type = "t2.micro"

  lifecycle {
    prevent_destroy = true
  }
}
```

## What Happens?

If someone runs:

```bash
terraform destroy
```

Terraform returns:

```text
Error: Instance cannot be destroyed
because prevent_destroy is set to true
```

## Use Cases

* Production databases
* Critical S3 buckets
* VPCs
* Route53 zones

## Benefits

✅ Prevents accidental deletion

✅ Protects critical infrastructure

## Considerations

Must remove the lifecycle rule before deleting the resource.

---

# 3. ignore_changes

## Purpose

Tells Terraform to ignore modifications to specific attributes.

Useful when another system manages part of the resource.

---

## Example: Auto Scaling Group

```hcl
resource "aws_autoscaling_group" "app_servers" {

  desired_capacity = 2

  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }
}
```

## Scenario

Initial state:

```text
desired_capacity = 2
```

CloudWatch Scaling Policy changes it to:

```text
desired_capacity = 4
```

Terraform will **not** attempt to revert it back to 2.

## Benefits

✅ Prevents configuration drift caused by external systems

✅ Works well with Auto Scaling

---

## Example: Ignore Tags

```hcl
resource "aws_instance" "example" {

  lifecycle {
    ignore_changes = [
      tags["Owner"]
    ]
  }
}
```

Useful when tags are managed by:

* AWS Organizations
* Cloud Governance Tools
* Security Platforms

---

# 4. replace_triggered_by

## Purpose

Forces a resource replacement whenever another resource changes.

---

## Security Group Example

### Security Group

```hcl
resource "aws_security_group" "app_sg" {
  name = "app-security-group"
}
```

### EC2 Instance

```hcl
resource "aws_instance" "app_with_sg" {

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.allowed_vms[0]
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  lifecycle {
    replace_triggered_by = [
      aws_security_group.app_sg
    ]
  }
}
```

## Behavior

Whenever the security group changes significantly, Terraform replaces the EC2 instance automatically.

## Use Cases

* Security group updates
* IAM profile changes
* AMI updates
* Dependency-driven rebuilds

## Benefits

✅ Ensures infrastructure consistency

✅ Useful for immutable infrastructure patterns

---

# 5. precondition

## Purpose

Validates a condition before resource creation.

Terraform stops execution if the condition fails.

---

## Example

```hcl
resource "aws_instance" "example" {

  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.allowed_vms[0]

  lifecycle {
    precondition {
      condition     = contains(["t2.micro", "t3.micro"], var.allowed_vms[0])
      error_message = "Only approved instance types are allowed."
    }
  }
}
```

## Result

If an invalid instance type is used:

```text
ERROR: Only approved instance types are allowed.
```

## Benefits

✅ Governance

✅ Cost control

✅ Security compliance

---

# 6. postcondition

## Purpose

Validates resource attributes after creation.

Ensures compliance requirements are met.

---

## Example: Compliance Validated S3 Bucket

```hcl
resource "aws_s3_bucket" "compliance_bucket" {

  bucket = "compliance-bucket-${var.environment}"

  tags = {
    Compliance = "SOC2"
    Environment = "Prod"
  }

  lifecycle {

    postcondition {
      condition     = contains(keys(self.tags), "Compliance")
      error_message = "Bucket must have a Compliance tag."
    }

    postcondition {
      condition     = contains(keys(self.tags), "Environment")
      error_message = "Bucket must have an Environment tag."
    }
  }
}
```

## Benefits

✅ Compliance enforcement

✅ Security validation

✅ Audit readiness

---

# AWS Example from Current Configuration

## Data Sources

### Latest Amazon Linux 2 AMI

```hcl
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

### Current AWS Region

```hcl
data "aws_region" "current" {}
```

### Available Availability Zones

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}
```

---

# Lifecycle Rules Summary

| Lifecycle Rule        | Purpose                               | Common AWS Use Case        |
| --------------------- | ------------------------------------- | -------------------------- |
| create_before_destroy | Create replacement before deletion    | EC2, ALB, Launch Templates |
| prevent_destroy       | Prevent accidental deletion           | RDS, S3, VPC               |
| ignore_changes        | Ignore external modifications         | ASG, Tags                  |
| replace_triggered_by  | Force recreation on dependency change | EC2 + Security Group       |
| precondition          | Validate before creation              | Governance Policies        |
| postcondition         | Validate after creation               | Compliance Checks          |

---

# Best Practices

### Production Infrastructure

```hcl
lifecycle {
  create_before_destroy = true
}
```

Use for:

* EC2
* ALB
* Launch Templates

---

### Critical Resources

```hcl
lifecycle {
  prevent_destroy = true
}
```

Use for:

* Databases
* Production S3 Buckets
* VPCs

---

### Auto Scaling Resources

```hcl
lifecycle {
  ignore_changes = [
    desired_capacity
  ]
}
```

Use when scaling policies manage capacity.

---

### Compliance Requirements

```hcl
lifecycle {
  postcondition {
    condition = contains(keys(self.tags), "Compliance")
    error_message = "Compliance tag missing."
  }
}
```

Use for regulated environments:

* SOC2
* ISO 27001
* HIPAA
* PCI DSS

---

# Conclusion

Terraform lifecycle rules provide fine-grained control over infrastructure behavior. They are essential for:

* Reducing downtime
* Preventing accidental destruction
* Managing external changes
* Enforcing compliance
* Building reliable AWS infrastructure

Mastering these lifecycle rules is a key step toward production-grade Infrastructure as Code (IaC) using Terraform and AWS.

# Day 21: AWS Policy and Governance Study Notes

This document provides a comprehensive explanation of AWS Policy and Governance implementation using Terraform. It breaks down the underlying AWS concepts (specifically **AWS Config** and **IAM Policy Enforcement**) and provides a line-by-line detailed explanation of the Terraform code in this workspace.

---

## 🛡️ 1. Understanding AWS Governance & Compliance Concepts

Cloud governance involves defining rules, policies, and structures to control cost, security, compliance, and performance on AWS. In this project, we implement two primary mechanisms:

### A. AWS Config (Continuous Compliance Auditing)
**AWS Config** is a service that enables you to assess, audit, and evaluate the configurations of your AWS resources. It continuously monitors and records resource configuration changes and allows you to audit them against desired configurations (rules).

*   **Configuration Recorder**: The engine that detects changes in your resources and records their configurations.
*   **Delivery Channel**: The mechanism that specifies where AWS Config sends configuration histories and snapshots. Typically, this is an **S3 bucket** (for storage) and optionally an **SNS topic** (for notifications).
*   **AWS Config Rules**: Compliance checks that represent your ideal configuration settings. If a resource deviates from a rule, AWS Config flags the resource as **non-compliant**. Rules can be:
    *   *Managed Rules*: Pre-built compliance checks provided by AWS (e.g., checking if root account has MFA enabled, or if S3 buckets block public access).
    *   *Custom Rules*: Compliance checks written as custom AWS Lambda functions.

### B. IAM Policy Enforcement (Prevention)
While AWS Config is *detective* (notifying you when something is non-compliant), IAM Policies are *preventative* (blocking actions that violate security guidelines).
*   **MFA-Protected Deletions**: Enforcing Multi-Factor Authentication for destructive actions.
*   **In-Transit Encryption**: Ensuring all data sent to S3 uses HTTPS (TLS/SSL).
*   **Tag Enforcement**: Restricting resource creation if standard tags (such as `Environment` or `Owner`) are missing.

---

## 📂 2. Project File Structure

The workspace is organized into modular Terraform files:

| File Name | Purpose |
| :--- | :--- |
| [provider.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day21/provider.tf) | Configures required providers (AWS, Random) and sets the region. |
| [variables.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day21/variables.tf) | Defines configurable inputs (AWS region, project prefix). |
| [main.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day21/main.tf) | Provisions the encrypted, version-controlled S3 bucket and policies for AWS Config storage. |
| [iam.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day21/iam.tf) | Defines preventative IAM policies (MFA, encryption, tagging) and the service role for AWS Config. |
| [config.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day21/config.tf) | Provisions the AWS Config Recorder, Delivery Channel, and compliance Rules. |
| [outputs.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day21/outputs.tf) | Outputs resource names, ARNs, and compliance information. |

---

## 🔍 3. Detailed Code Breakdown

### A. Provider Configuration ([provider.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day21/provider.tf))
Configures Terraform to download the appropriate AWS and Random providers.
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```
*   `~> 5.0` ensures we use any compatible `5.x` version of the AWS provider.
*   `region` is dynamically set using the `aws_region` input variable.

---

### B. S3 Storage for AWS Config ([main.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day21/main.tf))
AWS Config requires an S3 bucket to store recorded configuration history. To adhere to security best practices, the bucket is hardened:

1.  **Unique S3 Bucket Creation**:
    ```hcl
    resource "aws_s3_bucket" "config_bucket" {
      bucket        = "${var.project_name}-config-bucket-${random_string.suffix.result}"
      force_destroy = true
    }
    ```
    *   Appends a 6-character random suffix to ensure global S3 uniqueness.
    *   `force_destroy = true` allows Terraform to cleanly delete the bucket (and its contents) during teardown.

2.  **Versioning & SSE Encryption**:
    ```hcl
    resource "aws_s3_bucket_versioning" "config_bucket_versioning" {
      bucket = aws_s3_bucket.config_bucket.id
      versioning_configuration { status = "Enabled" }
    }

    resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket_encryption" {
      bucket = aws_s3_bucket.config_bucket.id
      rule {
        apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
      }
    }
    ```
    *   *Versioning* preserves historical states of audit logs.
    *   *Encryption at Rest* ensures that any audit log written to disk is encrypted using the industry-standard AES256 algorithm.

3.  **Public Access Block**:
    ```hcl
    resource "aws_s3_bucket_public_access_block" "config_bucket_public_access" {
      bucket = aws_s3_bucket.config_bucket.id
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
    ```
    *   Explicitly blocks any public ACLs or bucket policies, isolating the bucket from public access.

4.  **Bucket Policy for AWS Config Integration**:
    ```hcl
    resource "aws_s3_bucket_policy" "config_bucket_policy" {
      bucket = aws_s3_bucket.config_bucket.id
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "AWSConfigBucketPermissionsCheck"
            Effect = "Allow"
            Principal = { Service = "config.amazonaws.com" }
            Action   = "s3:GetBucketAcl"
            Resource = aws_s3_bucket.config_bucket.arn
          },
          {
            Sid    = "AWSConfigBucketExistenceCheck"
            Effect = "Allow"
            Principal = { Service = "config.amazonaws.com" }
            Action   = "s3:ListBucket"
            Resource = aws_s3_bucket.config_bucket.arn
          },
          {
            Sid    = "AWSConfigBucketPutObject"
            Effect = "Allow"
            Principal = { Service = "config.amazonaws.com" }
            Action   = "s3:PutObject"
            Resource = "${aws_s3_bucket.config_bucket.arn}/*"
            Condition = {
              StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
            }
          },
          {
            Sid       = "DenyInsecureTransport"
            Effect    = "Deny"
            Principal = "*"
            Action    = "s3:*"
            Resource = [
              aws_s3_bucket.config_bucket.arn,
              "${aws_s3_bucket.config_bucket.arn}/*"
            ]
            Condition = {
              Bool = { "aws:SecureTransport" = "false" }
            }
          }
        ]
      })
    }
    ```
    *   **AWSConfigBucketPermissionsCheck** & **AWSConfigBucketExistenceCheck**: Allows the AWS Config service to verify bucket ACLs and list bucket contents.
    *   **AWSConfigBucketPutObject**: Permits AWS Config to write log files into the bucket under the condition that they assert owner full control.
    *   **DenyInsecureTransport**: Denies any S3 requests made over plain HTTP (`aws:SecureTransport = false`), enforcing TLS/HTTPS in-transit encryption.

---

### C. Preventative IAM Policies & Roles ([iam.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day21/iam.tf))

This file defines policies designed to demonstrate preventative security enforcement, alongside the Service Role that AWS Config assumes to perform its scans.

1.  **MFA Delete Policy**:
    ```hcl
    resource "aws_iam_policy" "mfa_delete_policy" {
      name        = "${var.project_name}-mfa-delete-policy"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid      = "DenyDeleteWithoutMFA"
          Effect   = "Deny"
          Action   = "s3:DeleteObject"
          Resource = "*"
          Condition = {
            BoolIfExists = { "aws:MultiFactorAuthPresent" = "false" }
          }
        }]
      })
    }
    ```
    *   Ensures that an IAM identity cannot delete S3 objects unless they are authenticated with a Multi-Factor Authentication (MFA) device.

2.  **Tag Enforcement Policy**:
    ```hcl
    resource "aws_iam_policy" "require_tags_policy" {
      name        = "${var.project_name}-require-tags"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RequireTagsOnEC2"
            Effect = "Deny"
            Action = ["ec2:RunInstances"]
            Resource = "arn:aws:ec2:*:*:instance/*"
            Condition = {
              StringNotLike = { "aws:RequestTag/Environment" = ["dev", "staging", "prod"] }
            }
          },
          {
            Sid    = "RequireOwnerTag"
            Effect = "Deny"
            Action = ["ec2:RunInstances"]
            Resource = "arn:aws:ec2:*:*:instance/*"
            Condition = {
              "Null" = { "aws:RequestTag/Owner" = "true" }
            }
          }
        ]
      })
    }
    ```
    *   **RequireTagsOnEC2**: Denies launching EC2 instances if the `Environment` tag is not explicitly set to `dev`, `staging`, or `prod`.
    *   **RequireOwnerTag**: Denies launching EC2 instances if the request does not specify an `Owner` tag.

3.  **AWS Config Service Role**:
    ```hcl
    resource "aws_iam_role" "config_role" {
      name = "${var.project_name}-config-role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = { Service = "config.amazonaws.com" }
        }]
      })
    }

    resource "aws_iam_role_policy_attachment" "config_policy_attach" {
      role       = aws_iam_role.config_role.name
      policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
    }

    resource "aws_iam_role_policy" "config_s3_policy" {
      name = "${var.project_name}-config-s3-policy"
      role = aws_iam_role.config_role.id
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect = "Allow"
          Action = ["s3:GetBucketVersioning", "s3:PutObject", "s3:GetObject"]
          Resource = [
            aws_s3_bucket.config_bucket.arn,
            "${aws_s3_bucket.config_bucket.arn}/*"
          ]
        }]
      })
    }
    ```
    *   Defines an IAM Role that the `config.amazonaws.com` service trust principal can assume.
    *   Attaches the AWS-managed policy `AWS_ConfigRole` which grants AWS Config permissions to read resource configurations across your AWS account.
    *   Defines an inline policy granting AWS Config specific S3 permissions to save audit histories and check versioning status on the bucket we provisioned.

---

### D. AWS Config Configuration & Compliance Rules ([config.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day21/config.tf))

This file enables AWS Config and implements the compliance checks.

1.  **Configuration Recorder**:
    ```hcl
    resource "aws_config_configuration_recorder" "main" {
      name     = "${var.project_name}-recorder"
      role_arn = aws_iam_role.config_role.arn

      recording_group {
        all_supported                 = true
        include_global_resource_types = true
      }
    }
    ```
    *   `all_supported = true` directs AWS Config to track all regional resources.
    *   `include_global_resource_types = true` ensures global resources (like IAM users, groups, and roles) are also recorded.

2.  **Delivery Channel**:
    ```hcl
    resource "aws_config_delivery_channel" "main" {
      name           = "${var.project_name}-delivery-channel"
      s3_bucket_name = aws_s3_bucket.config_bucket.bucket
      depends_on     = [aws_config_configuration_recorder.main]
    }
    ```
    *   Connects the Config Recorder to write states to our S3 bucket.

3.  **Config Status (Enabling)**:
    ```hcl
    resource "aws_config_configuration_recorder_status" "main" {
      name       = aws_config_configuration_recorder.main.name
      is_enabled = true
      depends_on = [aws_config_delivery_channel.main]
    }
    ```
    *   Starts the recorder service. (Without this resource, AWS Config will be created but will remain inactive).

4.  **AWS Managed Config Rules**:
    ```hcl
    # S3 Public Write Prohibited
    resource "aws_config_config_rule" "s3_public_write_prohibited" {
      name = "s3-bucket-public-write-prohibited"
      source {
        owner             = "AWS"
        source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
      }
      depends_on = [aws_config_configuration_recorder.main]
    }

    # EBS Encryption Enabled
    resource "aws_config_config_rule" "ebs_encryption" {
      name = "encrypted-volumes"
      source {
        owner             = "AWS"
        source_identifier = "ENCRYPTED_VOLUMES"
      }
      depends_on = [aws_config_configuration_recorder.main]
    }
    ```
    *   Each rule leverages pre-configured AWS Managed Rules. The `source_identifier` indicates the exact rule template AWS provides.
    *   `depends_on = [aws_config_configuration_recorder.main]` ensures compliance monitoring rules are only established after the recorder engine itself is provisioned.

5.  **Config Rule with Parameters (`REQUIRED_TAGS`)**:
    ```hcl
    resource "aws_config_config_rule" "required_tags" {
      name = "required-tags"
      source {
        owner             = "AWS"
        source_identifier = "REQUIRED_TAGS"
      }
      input_parameters = jsonencode({
        tag1Key = "Environment"
        tag2Key = "Owner"
      })
      scope {
        compliance_resource_types = [
          "AWS::EC2::Instance",
          "AWS::S3::Bucket"
        ]
      }
      depends_on = [aws_config_configuration_recorder.main]
    }
    ```
    *   `input_parameters` allows passing specific inputs to the AWS Managed Rule. Here, we require the keys `Environment` and `Owner`.
    *   `scope` limits the rule check only to specific resource types (EC2 Instances and S3 Buckets), avoiding audit fees on other resource types.

---

## 🛠️ 4. Deploying & Testing the Setup

### Step 1: Initialize and Deploy
Execute the standard Terraform command cycle:
```bash
terraform init
terraform plan
terraform apply --auto-approve
```

### Step 2: Verify Config Recording Status
You can check if AWS Config is active and recording in the command line using:
```bash
aws configservice describe-configuration-recorder-status
```

### Step 3: Run Compliance Audits
AWS Config will begin scanning resources in the background. To immediately query rules and compliance status:
```bash
aws configservice describe-compliance-by-config-rule
```

---

## 💡 5. Essential Best Practices & Tips

1.  **Monitor AWS Config Costs**: AWS Config charges per configuration item recorded and per active rule evaluation. Use scopes (like the one in `required-tags`) to limit the types of resources checked.
2.  **Continuous Compliance Notifications**: In a production environment, pair the Delivery Channel with an **Amazon SNS (Simple Notification Service)** topic to alert security teams when compliance status shifts to `NON_COMPLIANT`.
3.  **Remediation**: Pair AWS Config rules with **Systems Manager (SSM) Automation Documents** to automatically remediate issues (e.g., automatically encrypting an unencrypted bucket or stopping non-compliant EC2 instances).

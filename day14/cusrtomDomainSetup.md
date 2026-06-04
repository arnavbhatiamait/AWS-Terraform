You're already at the **S3 + CloudFront + OAC** stage. Here's how to implement each item from the checklist on top of your current code.

---

# 1. Custom Domain with Route 53

Current:

```text
https://d123abcxyz.cloudfront.net
```

Desired:

```text
https://www.arnavbhatia.com
```

## Create Hosted Zone

```hcl
resource "aws_route53_zone" "main" {
  name = "arnavbhatia.com"
}
```

## Add Alias Record

```hcl
resource "aws_route53_record" "website" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
```

---

# 2. SSL Certificate using ACM

CloudFront requires ACM certificates in **us-east-1**.

## Additional Provider

```hcl
provider "aws" {
  region = "ap-south-1"
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}
```

## Certificate

```hcl
resource "aws_acm_certificate" "cert" {
  provider          = aws.virginia
  domain_name       = "www.arnavbhatia.com"
  validation_method = "DNS"
}
```

## Validation Record

```hcl
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => dvo
  }

  zone_id = aws_route53_zone.main.zone_id

  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}
```

## Certificate Validation

```hcl
resource "aws_acm_certificate_validation" "cert" {
  provider = aws.virginia

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}
```

## Update CloudFront

Replace:

```hcl
viewer_certificate {
  cloudfront_default_certificate = true
}
```

with:

```hcl
viewer_certificate {
  acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
  ssl_support_method       = "sni-only"
  minimum_protocol_version = "TLSv1.2_2021"
}
```

Add:

```hcl
aliases = ["www.arnavbhatia.com"]
```

---

# 3. CI/CD Pipeline

Current deployment:

```bash
terraform apply
```

Manual upload.

## GitHub Actions Example

```yaml
name: Deploy Website

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3

      - run: terraform init

      - run: terraform apply -auto-approve
```

For static files:

```yaml
- run: aws s3 sync ./www s3://your-bucket-name
```

You can later use:

* GitHub Actions
* AWS CodePipeline
* Jenkins

---

# 4. Multiple Environments

Current:

```hcl
bucket = var.bucket_name
```

Create:

```text
environments/
├── dev
├── staging
└── prod
```

Example:

```hcl
variable "environment" {
  type = string
}
```

```hcl
resource "aws_s3_bucket" "firstbucket" {
  bucket = "${var.environment}-website-bucket"
}
```

Deploy:

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

or

```bash
terraform apply -var-file=dev.tfvars
terraform apply -var-file=prod.tfvars
```

---

# 5. Custom Error Pages

If someone refreshes:

```text
https://site.com/about
```

S3 returns:

```text
403
```

Configure CloudFront:

```hcl
custom_error_response {
  error_code         = 403
  response_code      = 200
  response_page_path = "/index.html"
}
```

For React, Angular, Vue SPA apps this is essential.

---

# 6. Security Headers

Create Response Headers Policy:

```hcl
resource "aws_cloudfront_response_headers_policy" "security" {
  name = "security-headers"

  security_headers_config {

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
    }

    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
  }
}
```

Attach it:

```hcl
default_cache_behavior {
  ...

  response_headers_policy_id =
    aws_cloudfront_response_headers_policy.security.id
}
```

---

# 7. Add S3 Versioning

```hcl
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.firstbucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

---

# Production-Ready Architecture

```text
Users
  │
  ▼
Route53
  │
  ▼
CloudFront
  │
  ├── ACM SSL Certificate
  ├── Security Headers
  ├── Custom Error Pages
  └── OAC
          │
          ▼
Private S3 Bucket
          │
          ▼
Versioned Static Files

GitHub Actions
      │
      ▼
Terraform + S3 Sync
```

If your goal is to learn Terraform for interviews and real-world AWS deployments, the next best step is to implement **Route53 + ACM + Custom Error Pages + Security Headers** first. Those four additions make your current project look much closer to a production-grade static website deployment.

# Terraform AWS S3 + CloudFront Static Website Hosting (Private S3 Bucket) - Detailed Explanation

## Overview

This Terraform configuration creates a secure static website hosting architecture using:

1. **Amazon S3 Bucket** (Private)
2. **S3 Public Access Block**
3. **CloudFront Origin Access Control (OAC)**
4. **Bucket Policy allowing only CloudFront access**
5. **Automatic file upload to S3**
6. **CloudFront Distribution**

### Architecture Flow

```text
User
  ↓
CloudFront Distribution
  ↓ (Authenticated Request via OAC)
Private S3 Bucket
  ↓
Website Files (HTML, CSS, JS, Images)
```

The bucket remains completely private and only CloudFront can access its contents.

---

# 1. S3 Bucket Creation

```terraform
resource "aws_s3_bucket" "firstbucket" {
  bucket = var.bucket_name
}
```

## Explanation

Creates an S3 bucket.

### Components

#### Resource Type

```terraform
aws_s3_bucket
```

Creates an AWS S3 bucket.

#### Resource Name

```terraform
firstbucket
```

Terraform local name used for referencing.

Example:

```terraform
aws_s3_bucket.firstbucket.id
```

#### Bucket Name

```terraform
bucket = var.bucket_name
```

Uses a variable value.

Example:

```terraform
bucket_name = "my-static-website-bucket"
```

Result:

```text
my-static-website-bucket
```

---

# 2. Block Public Access

```terraform
resource "aws_s3_bucket_public_access_block" "block" {
```

Creates a Public Access Block configuration.

AWS provides four security controls.

---

## Bucket Association

```terraform
bucket = aws_s3_bucket.firstbucket.id
```

Attaches the settings to the bucket.

Example:

```text
my-static-website-bucket
```

---

## Block Public ACLs

```terraform
block_public_acls = true
```

Prevents users from creating public ACLs.

Blocked example:

```text
public-read
public-read-write
```

---

## Block Public Policies

```terraform
block_public_policy = true
```

Prevents bucket policies that allow public access.

Example blocked:

```json
{
  "Principal": "*"
}
```

---

## Ignore Public ACLs

```terraform
ignore_public_acls = true
```

Ignores any existing public ACLs.

Even if someone sets:

```text
public-read
```

AWS ignores it.

---

## Restrict Public Buckets

```terraform
restrict_public_buckets = true
```

Prevents public access even if a bucket policy accidentally becomes public.

---

## Security Result

Bucket is fully private.

Only authorized services can access it.

---

# 3. CloudFront Origin Access Control (OAC)

```terraform
resource "aws_cloudfront_origin_access_control" "oac" {
```

Creates a CloudFront Origin Access Control.

OAC is the modern replacement for OAI (Origin Access Identity).

---

## Name

```terraform
name = "demo-oac"
```

Friendly AWS name.

---

## Description

```terraform
description = "Origin Access Control for S3 bucket"
```

Documentation only.

---

## Signing Behavior

```terraform
signing_behavior = "always"
```

Every request from CloudFront to S3 is signed.

---

## Signing Protocol

```terraform
signing_protocol = "sigv4"
```

Uses AWS Signature Version 4 authentication.

AWS verifies:

* Request authenticity
* Request integrity

---

## Origin Type

```terraform
origin_access_control_origin_type = "s3"
```

Specifies the origin is an S3 bucket.

---

# Why OAC?

Without OAC:

```text
Internet
   ↓
S3 Bucket (Public)
```

With OAC:

```text
Internet
   ↓
CloudFront
   ↓
Private S3 Bucket
```

Much more secure.

---

# 4. Bucket Policy

```terraform
resource "aws_s3_bucket_policy" "bucket_policy"
```

Allows CloudFront to read objects.

---

## Attach Policy

```terraform
bucket = aws_s3_bucket.firstbucket.id
```

Applies policy to bucket.

---

## Dependency

```terraform
depends_on = [
  aws_s3_bucket_public_access_block.block
]
```

Ensures public access block is created first.

Terraform order:

```text
S3 Bucket
   ↓
Public Access Block
   ↓
Bucket Policy
```

---

## JSON Policy

```terraform
policy = jsonencode({...})
```

Converts Terraform object into JSON.

---

## Policy Version

```json
"Version": "2012-10-17"
```

AWS IAM policy version.

---

## Statement Section

```json
"Statement": [...]
```

Contains permissions.

---

## SID

```json
"Sid": "Statement1"
```

Optional identifier.

---

## Effect

```json
"Effect": "Allow"
```

Permission granted.

Possible values:

```text
Allow
Deny
```

---

## Principal

```json
"Principal": {
  "Service": "cloudfront.amazonaws.com"
}
```

Only CloudFront can use this permission.

---

## Actions

```json
"Action": [
  "s3:GetObject"
]
```

Allows reading objects.

Example:

```text
index.html
style.css
logo.png
```

CloudFront can fetch them.

---

## Resource

```json
"Resource": "${aws_s3_bucket.firstbucket.arn}/*"
```

Applies to every object.

Example:

```text
arn:aws:s3:::my-bucket/*
```

---

## Condition

```json
Condition = {
  StringEquals = {
      "AWS:SourceArn" =
      aws_cloudfront_distribution.s3_distribution.arn
  }
}
```

Only THIS CloudFront distribution can access bucket.

Even another CloudFront distribution cannot access it.

---

# 5. Upload Files to S3

```terraform
resource "aws_s3_object" "object"
```

Uploads website files.

---

## fileset()

```terraform
for_each = fileset("${path.module}/www", "**/*")
```

Reads all files recursively.

Example:

```text
www/
├── index.html
├── style.css
├── app.js
├── images/
│   └── logo.png
```

Returns:

```text
index.html
style.css
app.js
images/logo.png
```

---

## Create One Object Per File

Terraform creates:

```text
aws_s3_object.object["index.html"]
aws_s3_object.object["style.css"]
aws_s3_object.object["app.js"]
```

---

## Bucket

```terraform
bucket = aws_s3_bucket.firstbucket.id
```

Target bucket.

---

## Key

```terraform
key = each.value
```

S3 object name.

Example:

```text
index.html
```

---

## Source

```terraform
source =
"${path.module}/www/${each.value}"
```

Local file path.

Example:

```text
www/index.html
```

---

## ETag

```terraform
etag =
filemd5("${path.module}/www/${each.value}")
```

Calculates MD5 hash.

Benefits:

* Detects file changes
* Uploads only modified files

---

# Content Type Mapping

```terraform
content_type = lookup(...)
```

Sets proper MIME types.

---

## Examples

### HTML

```terraform
"html" = "text/html"
```

Browser renders page.

---

### CSS

```terraform
"css" = "text/css"
```

Loads styles.

---

### JavaScript

```terraform
"js" = "application/javascript"
```

Executes scripts.

---

### PNG

```terraform
"png" = "image/png"
```

Image rendering.

---

### SVG

```terraform
"svg" = "image/svg+xml"
```

Vector graphics.

---

## Fallback

```terraform
"application/octet-stream"
```

Used if extension is unknown.

---

# 6. CloudFront Distribution

```terraform
resource "aws_cloudfront_distribution" "s3_distribution"
```

Creates a CDN.

---

# Origin Configuration

```terraform
origin {
```

Defines content source.

---

## Domain Name

```terraform
domain_name =
aws_s3_bucket.firstbucket.bucket_regional_domain_name
```

Example:

```text
mybucket.s3.ap-south-1.amazonaws.com
```

---

## Origin ID

```terraform
origin_id = local.origin_id
```

Unique identifier.

Example:

```terraform
locals {
  origin_id = "myS3Origin"
}
```

---

## OAC

```terraform
origin_access_control_id =
aws_cloudfront_origin_access_control.oac.id
```

Links CloudFront to OAC.

---

# Distribution Settings

## Enabled

```terraform
enabled = true
```

Activates distribution.

---

## IPv6

```terraform
is_ipv6_enabled = true
```

Supports IPv6 clients.

---

## Default Root Object

```terraform
default_root_object = "index.html"
```

When user visits:

```text
https://example.cloudfront.net
```

CloudFront serves:

```text
index.html
```

---

# Default Cache Behavior

```terraform
default_cache_behavior
```

Controls caching and requests.

---

## Allowed Methods

```terraform
allowed_methods = ["GET","HEAD"]
```

Permits:

```text
GET
HEAD
```

No:

```text
POST
PUT
DELETE
```

Ideal for static websites.

---

## Cached Methods

```terraform
cached_methods = ["GET","HEAD"]
```

Only cache GET and HEAD requests.

---

## Target Origin

```terraform
target_origin_id = local.origin_id
```

Connects behavior to origin.

---

# Forwarded Values

```terraform
forwarded_values
```

Determines request data sent to origin.

---

## Query Strings

```terraform
query_string = false
```

Ignored.

Example:

```text
?page=1
```

Not forwarded.

---

## Cookies

```terraform
cookies {
  forward = "none"
}
```

No cookies sent to S3.

Improves cache efficiency.

---

# HTTPS Enforcement

```terraform
viewer_protocol_policy =
"redirect-to-https"
```

HTTP:

```text
http://example.com
```

Automatically becomes:

```text
https://example.com
```

---

# Cache TTLs

## Minimum TTL

```terraform
min_ttl = 0
```

No minimum cache requirement.

---

## Default TTL

```terraform
default_ttl = 3600
```

1 hour.

---

## Maximum TTL

```terraform
max_ttl = 86400
```

24 hours.

---

# Price Class

```terraform
price_class = "PriceClass_100"
```

Uses cheapest CloudFront edge locations.

Regions:

```text
North America
Europe
```

Lower cost.

---

# Geographic Restrictions

```terraform
restrictions {
  geo_restriction {
    restriction_type = "none"
  }
}
```

Accessible globally.

No country restrictions.

---

# SSL Certificate

```terraform
viewer_certificate {
  cloudfront_default_certificate = true
}
```

Uses AWS-managed CloudFront certificate.

Domain example:

```text
https://xxxx.cloudfront.net
```

No custom certificate needed.

---

# Complete Deployment Flow

```text
terraform apply
      │
      ▼
Create S3 Bucket
      │
      ▼
Block Public Access
      │
      ▼
Create Origin Access Control
      │
      ▼
Upload Website Files
      │
      ▼
Create CloudFront Distribution
      │
      ▼
Apply Bucket Policy
      │
      ▼
Website Live
```

---

# Security Summary

### Public Access

❌ Disabled

### Bucket ACLs

❌ Blocked

### Public Policies

❌ Blocked

### CloudFront Access

✅ Allowed

### Direct S3 Access

❌ Denied

### HTTPS

✅ Enforced

### Signed Requests

✅ OAC + SigV4

### Global CDN

✅ CloudFront

---

# Important Syntax Issues in Your Code

Your current configuration contains a few errors:

### Missing comma

```terraform
"svg"  = "image/svg+xml"
"txt"  = "text/plain"
```

Should be:

```terraform
"svg"  = "image/svg+xml",
"txt"  = "text/plain",
```

---

### Policy Condition Formatting

Inside `jsonencode()`:

```terraform
"Resource" : "${aws_s3_bucket.firstbucket.arn}/*"
Condition = {
```

Should be:

```terraform
"Resource" : "${aws_s3_bucket.firstbucket.arn}/*",
"Condition" : {
```

---

### CloudFront Dependency

Because bucket policy references:

```terraform
aws_cloudfront_distribution.s3_distribution.arn
```

Terraform may create a dependency cycle. Often this is solved using an `aws_iam_policy_document` data source or by applying policy after distribution creation.


## Variables and References Used in the Terraform Configuration

Your Terraform code uses several types of variables and built-in functions:

---

# 1. `var.bucket_name`

```terraform
resource "aws_s3_bucket" "firstbucket" {
  bucket = var.bucket_name
}
```

## Purpose

Specifies the name of the S3 bucket to create.

## Example Variable Definition

```terraform
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}
```

## Example Value

```terraform
bucket_name = "arnav-static-website-bucket"
```

or

```terraform
bucket_name = "my-company-website-prod"
```

## Why Use a Variable?

Instead of hardcoding:

```terraform
bucket = "arnav-static-website-bucket"
```

you can reuse the same Terraform code for different environments.

Example:

```terraform
dev-bucket
staging-bucket
prod-bucket
```

---

# 2. `local.origin_id`

Used here:

```terraform
origin_id = local.origin_id
```

and

```terraform
target_origin_id = local.origin_id
```

## Purpose

A local value used as a unique identifier for the CloudFront origin.

## Example

```terraform
locals {
  origin_id = "S3Origin"
}
```

CloudFront internally uses this ID to connect cache behaviors to origins.

---

# 3. `each.value`

Used in:

```terraform
for_each = fileset("${path.module}/www", "**/*")
```

```terraform
key = each.value
```

```terraform
source = "${path.module}/www/${each.value}"
```

```terraform
etag = filemd5("${path.module}/www/${each.value}")
```

## Purpose

Represents the current file being processed by the loop.

---

### Example Folder

```text
www/
├── index.html
├── style.css
├── app.js
```

Terraform executes:

| Iteration | each.value |
| --------- | ---------- |
| 1         | index.html |
| 2         | style.css  |
| 3         | app.js     |

---

### Example Result

```terraform
aws_s3_object.object["index.html"]
```

```terraform
aws_s3_object.object["style.css"]
```

```terraform
aws_s3_object.object["app.js"]
```

---

# 4. `path.module`

Used here:

```terraform
fileset("${path.module}/www", "**/*")
```

```terraform
source = "${path.module}/www/${each.value}"
```

## Purpose

Returns the directory where the current Terraform module exists.

---

### Example

Terraform project:

```text
project/
│
├── main.tf
├── variables.tf
└── www/
    ├── index.html
    └── style.css
```

Then:

```terraform
path.module
```

returns

```text
project
```

---

### Example Expansion

```terraform
"${path.module}/www/index.html"
```

becomes

```text
project/www/index.html
```

---

# 5. `aws_s3_bucket.firstbucket.id`

Used in:

```terraform
bucket = aws_s3_bucket.firstbucket.id
```

## Purpose

References the ID of the S3 bucket created earlier.

---

### Resource

```terraform
resource "aws_s3_bucket" "firstbucket" {
  bucket = var.bucket_name
}
```

Terraform automatically provides attributes.

---

### Common Attributes

| Attribute                   | Meaning           |
| --------------------------- | ----------------- |
| id                          | Bucket name       |
| arn                         | Bucket ARN        |
| bucket_regional_domain_name | Regional endpoint |
| bucket                      | Bucket name       |

---

### Example

```terraform
aws_s3_bucket.firstbucket.id
```

returns

```text
arnav-static-site
```

---

# 6. `aws_s3_bucket.firstbucket.arn`

Used in:

```terraform
"Resource" : "${aws_s3_bucket.firstbucket.arn}/*"
```

## Purpose

Returns bucket ARN.

Example:

```text
arn:aws:s3:::arnav-static-site
```

---

### After Adding `/*`

```text
arn:aws:s3:::arnav-static-site/*
```

Means:

```text
All objects inside bucket
```

---

# 7. `aws_s3_bucket.firstbucket.bucket_regional_domain_name`

Used in:

```terraform
domain_name =
aws_s3_bucket.firstbucket.bucket_regional_domain_name
```

## Purpose

Returns the regional endpoint of the bucket.

Example:

```text
mybucket.s3.ap-south-1.amazonaws.com
```

CloudFront uses this as the origin.

---

# 8. `aws_cloudfront_origin_access_control.oac.id`

Used in:

```terraform
origin_access_control_id =
aws_cloudfront_origin_access_control.oac.id
```

## Purpose

Returns the unique OAC ID.

Example:

```text
E3ABCD123XYZ
```

CloudFront uses this to authenticate requests to S3.

---

# 9. `aws_cloudfront_distribution.s3_distribution.arn`

Used in:

```terraform
"AWS:SourceArn" =
aws_cloudfront_distribution.s3_distribution.arn
```

## Purpose

Returns the CloudFront distribution ARN.

Example:

```text
arn:aws:cloudfront::123456789012:distribution/E123ABC456XYZ
```

---

### Why Used?

To ensure only THIS CloudFront distribution can access the bucket.

Without it:

```json
{
  "Service": "cloudfront.amazonaws.com"
}
```

Any CloudFront distribution could potentially access the bucket.

With SourceArn:

```json
{
  "AWS:SourceArn":
  "arn:aws:cloudfront::123456789012:distribution/E123ABC456XYZ"
}
```

Only your distribution can access it.

---

# Built-in Terraform Functions Used

---

## `fileset()`

```terraform
fileset("${path.module}/www", "**/*")
```

### Purpose

Returns all files in a directory.

Example:

```text
www/
├── index.html
├── css/style.css
├── js/app.js
```

Result:

```text
[
  "index.html",
  "css/style.css",
  "js/app.js"
]
```

---

## `filemd5()`

```terraform
filemd5("${path.module}/www/${each.value}")
```

### Purpose

Calculates MD5 checksum of a file.

Example:

```text
index.html
```

Returns:

```text
4d186321c1a7f0f354b297e8914ab240
```

Used to detect file changes.

---

## `lookup()`

```terraform
lookup(map, key, default)
```

Used here:

```terraform
lookup({
  "html" = "text/html"
}, extension, "application/octet-stream")
```

### Purpose

Find a value in a map.

Example:

```terraform
lookup({
  html = "text/html"
}, "html", "default")
```

Returns:

```text
text/html
```

---

## `split()`

```terraform
split(".", each.value)
```

### Example

```terraform
split(".", "index.html")
```

Returns:

```text
[
  "index",
  "html"
]
```

---

## `length()`

```terraform
length(split(".", each.value))
```

### Example

```terraform
length(["index","html"])
```

Returns:

```text
2
```

---

## `jsonencode()`

```terraform
policy = jsonencode({...})
```

### Purpose

Converts Terraform objects into valid JSON.

Terraform:

```terraform
{
  Effect = "Allow"
}
```

Becomes:

```json
{
  "Effect": "Allow"
}
```

---

# Summary Table

| Variable / Reference                                    | Type               | Purpose                          |
| ------------------------------------------------------- | ------------------ | -------------------------------- |
| `var.bucket_name`                                       | Input Variable     | S3 bucket name                   |
| `local.origin_id`                                       | Local Variable     | CloudFront origin identifier     |
| `each.value`                                            | Loop Variable      | Current file name                |
| `path.module`                                           | Built-in Variable  | Current module path              |
| `aws_s3_bucket.firstbucket.id`                          | Resource Attribute | Bucket name/ID                   |
| `aws_s3_bucket.firstbucket.arn`                         | Resource Attribute | Bucket ARN                       |
| `aws_s3_bucket.firstbucket.bucket_regional_domain_name` | Resource Attribute | S3 regional endpoint             |
| `aws_cloudfront_origin_access_control.oac.id`           | Resource Attribute | OAC ID                           |
| `aws_cloudfront_distribution.s3_distribution.arn`       | Resource Attribute | CloudFront ARN                   |
| `fileset()`                                             | Function           | Get files from directory         |
| `filemd5()`                                             | Function           | Generate file checksum           |
| `lookup()`                                              | Function           | Get value from map               |
| `split()`                                               | Function           | Split string                     |
| `length()`                                              | Function           | Count elements                   |
| `jsonencode()`                                          | Function           | Convert Terraform object to JSON |

resource "aws_s3_bucket" "firstbucket" {
  bucket = var.bucket_name

}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.firstbucket.id
  # ! The following settings block all public access to the S3 bucket, ensuring that it is not accessible to unauthorized users. This is a crucial security measure to protect sensitive data stored in the bucket.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# ! origin access control -> used to acces the private bucket from cloudfront distribution. It allows cloudfront to access the bucket securely without exposing it to the public. It ensures that only cloudfront can access the bucket, preventing unauthorized access and enhancing security.
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "demo-oac"
  description                       = "Origin Access Control for S3 bucket"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
  origin_access_control_origin_type = "s3"
}

# ! bucket policy -> used to allow cloudfront distribution to access the private bucket. It defines the permissions for the bucket, allowing cloudfront to read the objects in the bucket while keeping it private from public access.

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket     = aws_s3_bucket.firstbucket.id
  depends_on = [aws_s3_bucket_public_access_block.block]
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "cloudfront.amazonaws.com" # ! This allows CloudFront to access the S3 bucket securely, ensuring that only CloudFront can read the objects in the bucket while keeping it private from public access.
        },
        "Action" : ["s3:GetObject", "s3:ListBucket"],
        "Resource" : "${aws_s3_bucket.firstbucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
        # ! This policy allows CloudFront to read all objects in the S3 bucket, enabling it to serve content to users while maintaining the security of the bucket.
    }]
  })
}

# ! aws s3 bucket object -> used to create an object in the S3 bucket. It allows you to upload files to the bucket, making them available for access and distribution through CloudFront or other services.
resource "aws_s3_object" "object" {
  for_each = fileset("${path.module}/www", "**/*")
  # ! This creates an object for each file in the specified directory, allowing you to easily upload multiple files to the S3 bucket.
  bucket = aws_s3_bucket.firstbucket.id
  key    = each.value
  source = "${path.module}/www/${each.value}"
  etag   = filemd5("${path.module}/www/${each.value}")
  # ! The etag is used to ensure that the object is only updated if the file has changed, optimizing the upload process and reducing unnecessary updates to the S3 bucket.
  content_type = lookup({
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "gif"  = "image/gif",
    "svg"  = "image/svg+xml"
    "txt"  = "text/plain"
    "json" = "application/json"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.firstbucket.bucket_regional_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

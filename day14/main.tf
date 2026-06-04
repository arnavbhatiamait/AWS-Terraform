resource "aws_s3_bucket" "firstbucket"{
    bucket= var.bucket_name
}

resource "aws_s3_public_access_block" "block"{
    bucket = aws_s3_bucket.firstbucket.id
    # ! The following settings block all public access to the S3 bucket, ensuring that it is not accessible to unauthorized users. This is a crucial security measure to protect sensitive data stored in the bucket.
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}
# ! origin access control -> used to acces the private bucket from cloudfront distribution. It allows cloudfront to access the bucket securely without exposing it to the public. It ensures that only cloudfront can access the bucket, preventing unauthorized access and enhancing security.
resource "aws_cloudfront_origin_access_control" "oac"{
    name = "demo-oac"
    description = "Origin Access Control for S3 bucket"
    signing_behavior = "always"
    signing_protocol = "sigv4"
    origin_access_control_origin_type = "s3"
}

# ! bucket policy -> used to allow cloudfront distribution to access the private bucket. It defines the permissions for the bucket, allowing cloudfront to read the objects in the bucket while keeping it private from public access.


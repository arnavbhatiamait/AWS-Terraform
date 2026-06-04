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
# ! origin access control

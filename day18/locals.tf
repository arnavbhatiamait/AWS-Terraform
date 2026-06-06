locals{
    bucket_prefix         = "${var.project_name}-${var.environment}"
    upload_bucket_name    = "${local.bucket_prefix}-upload-${random_id.suffix.hex}"
    processed_bucket_name = "${local.bucket_prefix}-processed-${random_id.suffix.hex}"
    lambda_function_name  = "${var.project_name}-${var.environment}-processor"
}

# ! s3 buckets for source and destination
resource "aws_s3_bucket" "upload_bucket" {
  bucket = local.upload_bucket_name
}
resource "aws_s3_bucket_versioning" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket" "processed_bucket" {
  bucket = local.processed_bucket_name
}
resource "aws_s3_bucket_versioning" "processed_bucket" {
  bucket = aws_s3_bucket.processed_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}


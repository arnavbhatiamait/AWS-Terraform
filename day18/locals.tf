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

# ! bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "processed_bucket" {
  bucket = aws_s3_bucket.processed_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ! bucket public access block
resource "aws_s3_bucket_public_access_block" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_public_access_block" "processed_bucket" {
  bucket = aws_s3_bucket.processed_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ! Iam role and policy for lambda to access s3 buckets

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# ! Lambda policy to allow access to S3 buckets
resource "aws_iam_role_policy" "lambda_policy" {
    name = "${var.project_name}-${var.environment}-lambda-policy"
    role = aws_iam_role.lambda_role.id
    
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.upload_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.processed_bucket.arn}/*"
      }
    ]
  })
}

# ! lambda layer
resource "aws_lambda_layer_version" "pillow_layer" {
    filename="${path.module}/pillow_layer.zip"
    layer_name="${var.project_name}-pillow-layer"
    compatible_runtimes=["python3.12"]
    description = "Lambda layer containing Pillow library for image processing"

}

# ! Lambda function
data "archive_file" "lambda_zip"{
    
    type = "zip"
    source_file="${path.module}/lambda/lambda_function.py"
    output_path="${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "image_processor" {
    # file_name=data.archive_file.lambda_zip.output_path
    function_name = local.lambda_function_name
    role = aws_iam_role.lambda_role.arn
    handler = "lambda_function.lambda_handler"
    runtime = "python3.12"
    timeout = var.lambda_timeout
    memory_size = var.lambda_memory_size
    filename = data.archive_file.lambda_zip.output_path
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    layers = [aws_lambda_layer_version.pillow_layer.arn]


    environment {
        variables = {
            PROCESSED_BUCKET = aws_s3_bucket.processed_bucket.id
            LOG_LEVEL = "INFO"}
    }
}
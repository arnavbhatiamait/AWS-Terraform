locals{
    bucket_prefix         = "${var.project_name}-${var.environment}"
    upload_bucket_name    = "${local.bucket_prefix}-upload-${random_id.suffix.hex}"
    processed_bucket_name = "${local.bucket_prefix}-processed-${random_id.suffix.hex}"
    lambda_function_name  = "${var.project_name}-${var.environment}-processor"
}

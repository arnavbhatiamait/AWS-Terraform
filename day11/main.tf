resource "aws_s3_bucket" "example" {
  bucket = local.formatted_bucket_name

#   tags =merge(
#     var.default_tag,
#     var.envionment_tags,
#     )
    tags = local.new_tag
}
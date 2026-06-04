resource "aws_s3_bucket" "example" {
  bucket = "my-unique-bucket-name-12345"

  tags =merge(
    var.default_tag,
    var.envionment_tags,
    )
}
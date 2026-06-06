# Simple backend-only image processor
# ! Upload image to source S3 → Lambda triggers → Processes → Saves to destination S3

resource "random_id" "suffix" {
  byte_length = 4
}

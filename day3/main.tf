# ! create a s3 bucket
terraform{
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

# ! s3 bucket resource

resource "aws_s3_bucket" "first_bucket" {
    bucket = "my-tf-test-bucket-12345654321"
    tags ={
        Name = "my bucket"
        Environment = "Dev"
    }
}
# ! configuring s3 for saving state file
terraform{
    backend "s3" {
        bucket = "my-tf-state-bucket-123456543210"
        key    = "dev/terraform.tfstate"
        region = "ap-south-1"
        encrypt = true
        use_lockfile=true
    }
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

# ! configure provider
provider "aws" {
    region = "ap-south-1"
}
# ** create a s3 bucket
resource "aws_s3_bucket" "first_bucket" {
    bucket = "my-tf-test-bucket-12345654321"
    tags ={
        Name = "my bucket"
        Environment = "Dev"
    }
}
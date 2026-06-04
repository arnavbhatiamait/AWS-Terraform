# ** create a s3 bucket
resource "aws_s3_bucket" "first_bucket" {
    bucket = "my-tf-test-bucket-12345654321"
    region = var.region
    tags ={
        Name = local.bucket_name
        Environment = var.enviornment
    }
}

resource "aws_vpc" "sample"{
    cidr_block = "10.0.0.0/16"
    region = var.region
    tags = {
        Name = local.vpc_name
        Environment = var.enviornment
    }
}
resource "aws_instance" "example" {
    ami = "ami-016f910f55cb4096d"
    instance_type = "t3.micro"
    region = var.region
    tags = {
        Name = local.ec2_name
        Environment = var.enviornment
    }
}

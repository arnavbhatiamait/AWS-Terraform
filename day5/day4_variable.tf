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


# ! variable 
variable "enviornment"{
    description = "Environment for the resources"
    type = string
    default = "dev"
}
locals{
    env = var.enviornment 
    bucket_name = "${var.enviornment}-bucket"
    vpc_name = "${var.enviornment}-vpc"
    ec2_name = "${var.enviornment}-ec2-instance"

}
# ! configure provider
provider "aws" {
    region = "ap-south-1"
}
# ** create a s3 bucket
resource "aws_s3_bucket" "first_bucket" {
    bucket = "my-tf-test-bucket-12345654321"
    tags ={
        Name = local.bucket_name
        Environment = var.enviornment
    }
}

resource "aws_vpc" "sample"{
    cidr_block = "10.0.1.0/16"
    tags = {
        Name = local.vpc_name
        Environment = var.enviornment
    }
}
resource "aws_ec2_instance" "example" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = "t2.micro"
    tags = {
        Name = local.ec2_name
        Environment = var.enviornment
    }
}
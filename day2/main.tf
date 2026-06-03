terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}
# ! Provider configuration
provider "aws" {
    region = "ap-south-1"
}
# ! create a vpc
resource "aws_vpc" "example" {
    cidr_block = "10.0.0.0/16"
}

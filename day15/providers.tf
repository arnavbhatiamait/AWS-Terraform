terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}
provider "aws" {
    region = var.primary_reg
    alias  = "primary"
}
provider "aws" {
    alias  = "secondary"
    region = "us-east-1"
}
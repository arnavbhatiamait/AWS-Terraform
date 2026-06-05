terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}
provider "aws" {
    region = var.primary
    alias  = "primary"
}
provider "aws" {
    alias  = var.secondary
    region = "secondary"
}
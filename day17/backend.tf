terraform {
    backend "s3"{
    
        bucket = "my-tf-state-bucket-123456543210"
        key    = "dev/terraform.tfstate"
        region = "ap-south-1"
        encrypt = true
        use_lockfile=true
    
    }
}
# ! variable 
variable "primary_reg"{
    description = "Primary AWS provider configuration"
    default="ap-south-1"
}
variable "secondary_reg"{
    description = "Secondary AWS provider configuration"
    default="us-east-1"
}

variable "primary_vpc_cidr"{
    description = "CIDR block for the primary VPC"
    default = "10.0.0.0/16"
}
variable "secondary_vpc_cidr"{
    description = "CIDR block for the secondary VPC"
    default = "10.1.0.0/16"
}
variable "enviornment"{
    description = "Environment for the resources"
    type = string
    default = "staging"
}
variable "region"{
    description = "AWS region to deploy resources"
    type = string
    default = "ap-south-1"
}
variable "instance_count"{
    description = "Number of EC2 instances to create"
    type = number
    default = 1
}

variable "monitoring_enabled"{
    description = "Enable detailed monitoring for EC2 instances"
    type = bool
    default = true
}

variable "associate_public_ip"{
    description = "Associate public IP address with EC2 instances"
    type = bool
    default = true
}

variable "cidr_block"{
    description = "CIDR block for VPC"
    type = list(string)
    default = ["10.0.0.0/16", "198.168.0.0/16","172.16.0.0/12"]
}
variable "allowed_vms"{
    description = "List of allowed VM types"
    type = list(string)
    default = ["t3.micro", "t3.small", "t3a.micro"]
}

variable "allowed_regions"{
    description = "Set of allowed AWS regions"
    type = set(string)
    default = ["us-east-1", "us-west-2", "ap-south-1"]
}
variable "tags"{
    type = map(string)
    default = {
        Environment = "dev"
        name="dev-EC2-instance"
        created_by = "Terraform"
    }
}

variable "ingress_values"{
    description = "Tuple of ingress rule values (from_port, to_port, protocol)"
    type = tuple([number, number, string])
    default = [80, 80, "tcp"]
}

variable "config"{
    type = object({
        region = string
        instance_count=number
        monitoring = bool
    })
    default = {
        region = "ap-south-1"
        instance_count = 1
        monitoring = true
    }
}

variable "bucket_names"{
    description = "List of S3 bucket names to create"
    type = list(string)
    default = ["my-tf-state-bucket1iufwbdnuin", "fksioeriomy-tf-state-bucket2", "my-tf-state-bucket3dnbfduiw"]
}
variable "bucket_names_set"{
    description = "List of S3 bucket names to create"
    type = set(string)
    default = ["my-tf-state-bucket1iufwbdnuin_set", "fksioeriomy-tf-state-bucket2_set", "my-tf-state-bucket3dnbfduiw_set"]
}
variable "ingress_rules"{
    description = "List of ingress rules for security group"
    type = list(object({
        from_port   = number
        to_port     = number
        protocol    = string
        cidr_blocks = list(string)
        description = string
    }))
    default = [
        {
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
            description = "Allow HTTP from anywhere"
        },
        {
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
            description = "Allow HTTPS from anywhere"
        }
    ]
}

variable "aws_vpc"{
    description = "VPC ID to launch instances in"
    type = string
    default = "vpc-12345678"
}

variable "bucket_name"{
    description = "Name of the S3 bucket to create"
    type = string
    default = "my-unique-tf-state-bucket-1234567890324"
    }
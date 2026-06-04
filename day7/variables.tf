# ! variable 
variable "enviornment"{
    description = "Environment for the resources"
    type = string
    default = "dev"
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
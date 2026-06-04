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
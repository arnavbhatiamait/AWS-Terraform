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
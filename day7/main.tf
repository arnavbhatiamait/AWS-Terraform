
resource "aws_instance" "example" {
    count =var.instance_count 
    ami = "ami-016f910f55cb4096d"
    instance_type = "t3.micro"
    region = var.region
    monitoring = var.monitoring_enabled
    associate_public_ip_address = var.associate_public_ip
    tags = {
        Name = local.ec2_name
        Environment = var.enviornment
    }
}

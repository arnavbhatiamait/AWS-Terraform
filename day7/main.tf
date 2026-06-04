
resource "aws_instance" "example" {
    count =var.instance_count 
    ami = "ami-016f910f55cb4096d"
    instance_type = var.allowed_vms[0]
    # region = var.region
    # ! use set
    region=tolist(var.allowed_regions)[2]
    monitoring = var.monitoring_enabled
    associate_public_ip_address = var.associate_public_ip
    # tags = {
    #     Name = local.ec2_name
    #     Environment = var.enviornment
    # }

    tags = var.tags
}

# ! added security groups
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"

  tags = {
    Name = "allow_tls"
  }
}

# ! added security group rules
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = var.cidr_block[0]  # Using the first CIDR block from the list variable
  from_port         = var.ingress_values[0]
  ip_protocol       = var.ingress_values[2]
  to_port           = var.ingress_values[1]
}

# ! added egress rules to allow all outbound traffic
# ~ egress-> outgoing traffic from the security group
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = var.cidr_block[0]  # Using the first CIDR block from the list variable
  ip_protocol       = "-1" # semantically equivalent to all ports
}


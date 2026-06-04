resource "aws_instance" "example"{
    ami="ami-016f910f55cb4096d"
    count=var.instance_count
    # instance_type=var.allowed_vms[0]
    # ! conditional expression to set instance type based on environment variable
    instance_type=var.enviornment=="dev" ? "t3.micro" : "t3.small"
    tags=var.tags
}
resource "aws_security_group" "example_sg"{
    name="example-security-group"
    description="Security group for example instances"
    # vpc_id=

    dynamic "ingress" {
        for_each = var.ingress_rules
        content {
            from_port = ingress.value.from_port
            to_port = ingress.value.to_port
            protocol = ingress.value.protocol
            cidr_blocks = ingress.value.cidr_blocks
            }

    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_instance" "example"{
    ami="ami-016f910f55cb4096d"
    count=var.instance_count
    # instance_type=var.allowed_vms[0]
    # ! conditional expression to set instance type based on environment variable
    instance_type=var.enviornment=="dev" ? "t3.micro" : "t3.small"
    tags=var.tags
}
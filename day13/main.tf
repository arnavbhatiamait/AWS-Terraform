data "aws_vpc" "vpc_name"{
    filter {
        name   = "tag:Name"
        values = ["default"]
    }
}
data "aws_subnet" "shared"{
    filter{
        name="tag:Name"
        values = ["subneta"]
    }
    vpc_id = data.aws_vpc.vpc_name.id
}

data "aws_ami" "linux2"{
    owners = ["amazon"]
    most_recent = true
    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_instance" "example"{
    ami = data.aws_ami.linux2.id
    count = var.instance_count
    instance_type = "t3.micro"
    tags = var.tags
    subnet_id = data.aws_subnet.shared.id
    # private_ip = cidrhost(data.aws_subnet_ids.shared.ids[0], 10)
}

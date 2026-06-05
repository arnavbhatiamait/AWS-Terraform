resource "aws_vpc" "primary_vpc"{
    cidr_block = var.primary_vpc_cidr
    provider = aws.primary
    enable_dns_support = true
    enable_dns_hostnames = true
    instance_tenancy = "default"
    tags = {
        Name = "primary-vpc-${var.primary_reg}"
    }

}

resource "aws_vpc" "secondary_vpc"{
    cidr_block = var.secondary_vpc_cidr
    provider = aws.secondary
    enable_dns_support = true
    enable_dns_hostnames = true
    instance_tenancy = "default"
    tags = {
        Name = "secondary-vpc-${var.secondary_reg}"
    }

}

# ! creating subnets in both VPCs
resource "aws_subnet" "primary_subnet"{
    vpc_id = aws_vpc.primary_vpc.id
    cidr_block = var.primary_vpc_cidr
    provider= aws.primary
    availability_zone = data.aws_availability_zones.primary.names[0]
    map_public_ip_on_launch = true
    tags = {
        Name = "primary-subnet-${var.primary_reg}"
        Environment = "Demo"
    }
}

resource "aws_subnet" "secondary_subnet"{
    vpc_id = aws_vpc.secondary_vpc.id
    cidr_block = var.secondary_vpc_cidr
    provider= aws.secondary
    availability_zone = data.aws_availability_zones.secondary.names[0]
    map_public_ip_on_launch = true
    tags = {
        Name = "secondary-subnet-${var.secondary_reg}"
        Environment = "Demo"
    }
}

# ! internet gateway resource 
resource "aws_internet_gateway" "primary_igw"{
    vpc_id = aws_vpc.primary_vpc.id
    provider = aws.primary
    tags = {
        Name = "primary-igw-${var.primary_reg}"
        Environment = "Demo"
    }
}

resource "aws_internet_gateway" "secondary_igw"{
    vpc_id = aws_vpc.secondary_vpc.id
    provider = aws.secondary
    tags = {
        Name = "secondary-igw-${var.secondary_reg}"
        Environment = "Demo"
    }
}

# ! route table resource
resource "aws_route_table" "primary_rt"{
    provider = aws.primary
    vpc_id = aws_vpc.primary_vpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.primary_igw.id
    }

    tags = {
        Name = "primary-rt-${var.primary_reg}"
        Environment = "Demo"
    }
}

resource "aws_route_table" "secondary_rt"{
    provider = aws.secondary
    vpc_id = aws_vpc.secondary_vpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.secondary_igw.id
    }
    tags = {
        Name = "secondary-rt-${var.secondary_reg}"
        Environment = "Demo"
    }
}


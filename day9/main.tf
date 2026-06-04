data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
data "aws_region" "current" {
    
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_launch_template" "app_server" {
  name_prefix   = "app-server-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.allowed_vms[0]

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "App Server from ASG"
        Demo = "ignore_changes"
      }
    )
  }
}


resource aws_instance example{
    # ami="ami-016f910f55cb4096d"
    ami="ami-03f4878755434977f"
    instance_type=var.allowed_vms[0]
    region=tolist(var.allowed_regions)[0]
    monitoring=var.monitoring_enabled
    tags=var.tags
    lifecycle{
        create_before_destroy=true
        # prevent_destroy=true
    }

}
# ! creatre_before_destroy will create new resource before destroying the old one, it is used to avoid downtime during updates or changes to the resource. It ensures that the new resource is fully provisioned and operational before the old resource is terminated, which can be crucial for maintaining availability and minimizing disruptions in production environments.
# ? prevent_destroy will prevent the resource from being destroyed, even if it is no longer needed or if the configuration changes. This can be useful for critical resources that should not be accidentally deleted, but it can also lead to issues if not used carefully, as it may prevent necessary updates or cleanups from occurring.


# ! Auto scaling group
resource "aws_autoscaling_group" "app_servers" {
  name               = "app-servers-asg"
  min_size           = 1
  max_size           = 5
  desired_capacity   = 2
  health_check_type  = "EC2"
  availability_zones = data.aws_availability_zones.available.names

  launch_template {
    id      = aws_launch_template.app_server.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "App Server ASG"
    propagate_at_launch = true
  }

  tag {
    key                 = "Demo"
    value               = "ignore_changes"
    propagate_at_launch = false
  }

  lifecycle {
    ignore_changes = [
      desired_capacity,
    ]
  }
}



resource "aws_security_group" "app_sg" {
  name        = "app-security-group"
  description = "Security group for application servers"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "App Security Group"
      Demo = "replace_triggered_by"
    }
  )
}

resource "aws_instance" "app_with_sg" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.allowed_vms[0]
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = merge(
    var.tags,
    {
      Name = "App Instance with Security Group"
      Demo = "replace_triggered_by"
    }
  )
}


resource "aws_s3_bucket" "compliance_bucket" {
  bucket = "compliance-bucket-${var.enviornment}-${data.aws_region.current.name}"

  tags = merge(
    var.tags,
    {
      Name       = "Compliance Validated Bucket"
      Demo       = "postcondition"
      Compliance = "SOC2"
    }
  )
  lifecycle {
    postcondition {
      condition     = contains(keys(self.tags), "Compliance")
      error_message = "ERROR: Bucket must have a 'Compliance' tag for audit purposes!"
    }

    postcondition {
      condition     = contains(keys(self.tags), "Environment")
      error_message = "ERROR: Bucket must have an 'Environment' tag!"
    }
  }
}
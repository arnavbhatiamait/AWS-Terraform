# Terraform Day 19 Example

This folder contains a **complete Terraform configuration** that demonstrates how to provision an Amazon EC2 instance with associated networking, security, and provisioners. The configuration is split across multiple `.tf` files for clarity and modularity.

---

## Overview

- **Provider & Variables** – `provider.tf` defines the AWS provider and a variable for the AWS region.
- **Backend** – `backend.tf` configures a remote S3 backend for state storage.
- **Data Sources** – `main.tf` uses data sources to fetch the latest Ubuntu AMI and the default VPC.
- **Security Group** – `main.tf` creates a security group allowing SSH access.
- **EC2 Instance** – `main.tf` spins up an `aws_instance` with:
  - Ubuntu Jammy 22.04 AMI
  - Instance type & key name from variables
  - The SSH security group attached
  - Connection block for remote provisioners
  - Remote‑exec provisioner that updates the package list and writes a test file.
- **Outputs** – `outputs.tf` outputs the instance ID and public IP.
- **Variables** – `variables.tf` defines the variables used throughout the configuration.

---

## File Breakdown

### `provider.tf`
```hcl
# Provider configuration separated for clarity.
variable "aws_region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "ap-south-1"
}

provider "aws" {
  region = var.aws_region
}

# NOTE: If you want to use a remote backend (S3 + DynamoDB) place config in backend.tf
```
- Declares a variable `aws_region` (default: `ap-south-1`).
- Configures the AWS provider to use that region.

### `backend.tf`
```hcl
terraform {
  backend "s3" {
    bucket        = "my-tf-state-bucket-123456543210"
    key           = "dev/terraform.tfstate"
    region        = "ap-south-1"
    encrypt       = true
    use_lockfile  = true
  }
}
```
- Stores the Terraform state remotely in an S3 bucket with state locking.

### `variables.tf`
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of existing AWS key pair"
  type        = string
  default     = "my-key"
}

variable "ssh_user" {
  description = "SSH user for remote provisioner"
  type        = string
  default     = "ubuntu"
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
  default     = "~/.ssh/id_rsa"
}
```
- Holds configurable values for the EC2 instance and SSH connection.

### `main.tf`
```hcl
# Get the latest Ubuntu Jammy AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu official)
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Reference the default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group allowing inbound SSH
resource "aws_security_group" "ssh" {
  name        = "tf-prov-demo-ssh"
  description = "Allow SSH inbound"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance definition
resource "aws_instance" "demo" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "terraform-provisioner-demo"
  }

  # Connection details for remote provisioner
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  # Remote‑exec provisioner that runs after the instance is reachable
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "echo 'Hello from remote-exec'| sudo tee /tmp/remote-exec.txt",
    ]
  }
}
```
- **Data sources** fetch the latest Ubuntu AMI and the default VPC.
- **Security group** opens port 22 for SSH from anywhere.
- **Instance** uses the fetched AMI, attaches the SG, and defines tags.
- **Connection block** provides SSH details for provisioners.
- **Remote‑exec provisioner** updates packages and writes a simple test file.

### `outputs.tf`
```hcl
output "instance_id" {
  description = "ID of the demo EC2 instance"
  value       = aws_instance.demo.id
}

output "public_ip" {
  description = "Public IP of the demo EC2 instance"
  value       = aws_instance.demo.public_ip
}
```
- Exposes the instance ID and its public IP for downstream consumption.

---

## How to Use
1. **Initialize** the working directory:
   ```bash
   terraform init
   ```
2. **Review** the plan:
   ```bash
   terraform plan
   ```
3. **Apply** to create resources:
   ```bash
   terraform apply
   ```
4. After apply, you can retrieve the outputs (`instance_id`, `public_ip`).
5. When finished, **destroy** resources to avoid charges:
   ```bash
   terraform destroy
   ```

---

## Notes & Best Practices

- The backend requires an existing S3 bucket (`my-tf-state-bucket-123456543210`) and appropriate IAM permissions.
- Ensure the SSH key (`var.key_name`) exists in the selected region.
- The remote‑exec provisioner runs **after** the instance is reachable; for more complex bootstrapping, consider using a user‑data script or a configuration management tool.
- Sensitive data such as private keys should be managed via a secrets manager rather than hard‑coded paths.

## Useful Terraform Commands

- **terraform taint RESOURCE** – Manually mark a resource as needing replacement on the next apply. Example:
  ```bash
  terraform taint aws_instance.demo
  ```

- **terraform state rm RESOURCE** – Remove a resource from the state if you no longer want Terraform to manage it.

- **terraform lock** – Terraform automatically acquires a state lock when using a remote backend that supports locking (e.g., S3 with DynamoDB). This prevents concurrent runs from corrupting the state. You can manually force a lock with `terraform force-unlock LOCK_ID` if needed.

- **terraform force-unlock LOCK_ID** – Manually remove a stale lock if an operation was interrupted.

---

## References
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Remote provisioners: https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec

---

*End of README*

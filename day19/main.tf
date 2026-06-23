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
data "aws_vpc" "default" {
  default = true
}
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

resource "aws_instance" "demo" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "terraform-provisioner-demo"
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

    # ! local exec
#       provisioner "local-exec" {
#     command = "echo 'Local-exec: created instance ${self.id} with IP ${self.public_ip}'"
#   }

    # ! remote exec

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "echo 'Hello from remote-exec'| sudo tee /tmp/remote-exec.txt"
]
  }

#   ! file provisioner
#   provisioner "file" {
#     source      = "${path.module}/scripts/welcome.sh"
#     destination = "/tmp/welcome.sh"
#   }
#   provisioner "remote-exec" {
#     inline = [
#       "chmod +x /tmp/welcome.sh",
#       "sudo /tmp/welcome.sh"
#     ]
#   }
}
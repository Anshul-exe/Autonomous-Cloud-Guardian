terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# SSH Key Pair
resource "aws_key_pair" "cloud_guardian_key" {
  key_name   = "Cloud-Guardian"
  public_key = file("Cloud-Guardian.pub")
}

# Security Group
resource "aws_security_group" "cloud_guardian_sg" {
  name        = "cloud-guardian-sg"
  description = "Security group for Cloud Guardian project"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node.js application"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "cloud-guardian-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_ssm_parameter" "ec2_ip" {
  name      = "/cloud-guardian/ec2-public-ip"
  type      = "String"
  value     = aws_instance.cloud_guardian.public_ip
  overwrite = true

  tags = {
    Project   = "cloud-guardian"
    ManagedBy = "terraform"
  }
}

# EC2 Instance
resource "aws_instance" "cloud_guardian" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.cloud_guardian_key.key_name

  vpc_security_group_ids      = [aws_security_group.cloud_guardian_sg.id]
  associate_public_ip_address = true

  monitoring = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              EOF

  tags = {
    Name        = "cloud-guardian-app"
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}

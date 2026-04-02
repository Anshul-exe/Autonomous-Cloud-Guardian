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

# IAM Role for EC2 to write CloudWatch Logs
resource "aws_iam_role" "ec2_role" {
  name = "cloud-guardian-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Project   = "cloud-guardian"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy" "ec2_cloudwatch_policy" {
  name = "cloud-guardian-ec2-cloudwatch"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/cloud-guardian/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "cloud-guardian-ec2-profile"
  role = aws_iam_role.ec2_role.name
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
  ami                  = data.aws_ami.amazon_linux_2.id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.cloud_guardian_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

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
    Project     = "cloud-guardian"
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}
# Idle test instance (will be stopped by Lambda)
resource "aws_instance" "idle_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.cloud_guardian_key.key_name

  vpc_security_group_ids      = [aws_security_group.cloud_guardian_sg.id]
  associate_public_ip_address = true

  monitoring = true

  # No user_data = no Docker, no workload = idle

  tags = {
    Name        = "cloud-guardian-idle-test"
    Project     = "cloud-guardian"
    Environment = "demo"
    ManagedBy   = "terraform"
    Purpose     = "FinOps-Test"
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
}

variable "my_ip" {
  description = "Your public IP for SSH access"
  type        = string
  default     = "157.49.112.163/32"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port for Node.js application"
  type        = number
  default     = 3000
}

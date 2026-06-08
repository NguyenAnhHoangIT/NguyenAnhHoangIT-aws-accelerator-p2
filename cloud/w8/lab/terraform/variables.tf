# ─────────────────────────────────────────────────────────────
# Input Variables
# ─────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "disc-player"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type (minikube needs >= 2 vCPU)"
  type        = string
  default     = "t3.medium"
}

variable "app_port" {
  description = "Port on EC2 host for kubectl port-forward (ALB targets this)"
  type        = number
  default     = 30080
}

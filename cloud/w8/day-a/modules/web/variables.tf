variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ASG and ALB"
  type        = list(string)
}

variable "environment" {
  description = "Environment name used for tagging resources"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type for ASG"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum size of ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size of ASG"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired capacity of ASG"
  type        = number
  default     = 2
}

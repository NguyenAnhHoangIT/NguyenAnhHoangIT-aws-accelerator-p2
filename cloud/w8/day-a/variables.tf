variable "aws_region" {
  description = "The AWS region to deploy all resources in"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name used for tagging resources"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
  default     = "webdb"
}

variable "db_username" {
  description = "Username for the database administrator"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Password for the database administrator"
  type        = string
  default     = "SecurePassword123!"
  sensitive   = true
}

variable "db_password_version" {
  description = "Version of the database password, increment to trigger a password rotation when using password_wo"
  type        = number
  default     = 1
}

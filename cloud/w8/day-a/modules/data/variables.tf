variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "database_subnet_ids" {
  description = "List of private subnet IDs for RDS Database Subnet Group"
  type        = list(string)
}

variable "web_sg_id" {
  description = "The ID of the web security group to allow connection to RDS"
  type        = string
}

variable "environment" {
  description = "Environment name used for tagging resources"
  type        = string
  default     = "dev"
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

variable "db_instance_class" {
  description = "The RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "The allocated storage size in GBs"
  type        = number
  default     = 20
}

variable "db_password_version" {
  description = "Version of the database password, increment to trigger a password rotation when using password_wo"
  type        = number
  default     = 1
}

# --- DATABASE SECURITY GROUP ---

resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security Group for RDS allowing ingress strictly from Web instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL access strictly from Web Security Group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.web_sg_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-rds-sg"
    Environment = var.environment
  }
}

# --- DATABASE SUBNET GROUP ---

resource "aws_db_subnet_group" "db_subnet_gp" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

# --- RDS POSTGRESQL INSTANCE ---

resource "aws_db_instance" "db" {
  identifier             = "${var.environment}-postgres"
  engine                 = "postgres"
  engine_version         = "16.1"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = 100
  db_name                = var.db_name
  username               = var.db_username
  password_wo            = var.db_password
  password_wo_version    = var.db_password_version
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_gp.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true

  tags = {
    Name        = "${var.environment}-postgres-db"
    Environment = var.environment
  }
}

# --- S3 BUCKET (ASSETS CHẶN PUBLIC) ---

resource "aws_s3_bucket" "assets" {
  bucket        = "${var.environment}-assets-bucket-nguyenanhhoangit"
  force_destroy = true

  tags = {
    Name        = "${var.environment}-assets-bucket"
    Environment = var.environment
  }
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS database"
  value       = aws_db_instance.db.endpoint
}

output "s3_bucket_id" {
  description = "The ID/Name of the S3 bucket"
  value       = aws_s3_bucket.assets.id
}

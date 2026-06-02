output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.web.alb_dns_name
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS database"
  value       = module.data.rds_endpoint
}

output "s3_bucket_name" {
  description = "The ID/Name of the S3 bucket"
  value       = module.data.s3_bucket_id
}

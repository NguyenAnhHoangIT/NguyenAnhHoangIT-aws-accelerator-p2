# ─────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────

output "app_url" {
  description = "URL to access the Disc Player via ALB"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance (for SSH debugging)"
  value       = aws_instance.minikube.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i ${var.project_name}-key.pem ubuntu@${aws_instance.minikube.public_ip}"
}

output "ssh_private_key" {
  description = "SSH private key (use: terraform output -raw ssh_private_key > key.pem)"
  value       = tls_private_key.ec2.private_key_pem
  sensitive   = true
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "s3_bucket_name" {
  description = "S3 bucket containing app files"
  value       = aws_s3_bucket.app.id
}

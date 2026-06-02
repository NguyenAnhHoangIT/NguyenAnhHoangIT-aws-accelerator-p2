output "web_sg_id" {
  description = "The ID of the security group for the web servers"
  value       = aws_security_group.web.id
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.web_alb.dns_name
}

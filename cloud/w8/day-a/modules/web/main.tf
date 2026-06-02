data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- SECURITY GROUPS ---

resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security Group for ALB allowing inbound HTTP"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Security Group for Web servers allowing traffic strictly from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow inbound HTTP from ALB Security Group"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic for installing packages"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-web-sg"
    Environment = var.environment
  }
}

# --- LOAD BALANCER ---

resource "aws_lb" "web_alb" {
  name                       = "${var.environment}-web-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true

  tags = {
    Name        = "${var.environment}-web-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "web_tg" {
  name        = "${var.environment}-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.environment}-web-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# --- LAUNCH TEMPLATE ---

resource "aws_launch_template" "web" {
  name_prefix   = "${var.environment}-web-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl enable nginx
              systemctl start nginx

              # Query metadata via IMDSv2
              TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
              AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

              cat <<HTML > /usr/share/nginx/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                  <title>NguyenAnhHoangIT AWS Demo</title>
                  <meta charset="utf-8">
                  <style>
                      body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0f172a; color: #f8fafc; text-align: center; padding: 50px; }
                      .card { background: rgba(255, 255, 255, 0.05); border-radius: 16px; backdrop-filter: blur(10px); border: 1px solid rgba(255, 255, 255, 0.1); display: inline-block; padding: 40px; box-shadow: 0 4px 30px rgba(0, 0, 0, 0.15); margin-top: 50px; }
                      h1 { color: #38bdf8; font-size: 2.5rem; margin-bottom: 20px; }
                      p { font-size: 1.2rem; line-height: 1.6; }
                      .info { font-family: monospace; background: #1e293b; padding: 6px 12px; border-radius: 6px; border: 1px solid #334155; color: #34d399; }
                      .footer { margin-top: 30px; font-size: 0.9rem; color: #64748b; }
                  </style>
              </head>
              <body>
                  <div class="card">
                      <h1>🚀 3-Tier Modular AWS Architecture</h1>
                      <p>Chào mừng đến với hệ thống được dựng hoàn chỉnh bằng <strong>Terraform Modules</strong>!</p>
                      <p>Instance ID: <span class="info">$INSTANCE_ID</span></p>
                      <p>Availability Zone: <span class="info">$AZ</span></p>
                      <div class="footer">NguyenAnhHoangIT - AWS Accelerator Phase 2</div>
                  </div>
              </body>
              </html>
              HTML
              EOF
  )

  # Enforce IMDSv2 for security best practices
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-web-instance"
      Environment = var.environment
    }
  }
}

# --- AUTO SCALING GROUP ---

resource "aws_autoscaling_group" "web_asg" {
  name_prefix         = "${var.environment}-web-asg-"
  vpc_zone_identifier = var.public_subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  tag {
    key                 = "Name"
    value               = "${var.environment}-web-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

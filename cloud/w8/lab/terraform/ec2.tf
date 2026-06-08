# ─────────────────────────────────────────────────────────────
# EC2 Instance + TLS Key Pair (Multi-Provider Wiring)
#
# TLS provider generates SSH key → feeds into AWS key pair
# This demonstrates wiring between two Terraform providers
# ─────────────────────────────────────────────────────────────

# ── TLS Provider: Generate SSH Key Pair ──────────────────────
resource "tls_private_key" "ec2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ── AWS Provider: Register the TLS-generated public key ──────
# This is the provider wiring: tls output → aws input
resource "aws_key_pair" "ec2" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ec2.public_key_openssh
}

# ── Save private key locally for SSH debugging ───────────────
resource "local_file" "private_key" {
  content         = tls_private_key.ec2.private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0600"
}

# ── EC2 Instance (Minikube Host) ─────────────────────────────
resource "aws_instance" "minikube" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2.key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # 30GB gp3 for Docker images + video files
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # Bootstrap: install Docker + minikube + deploy app
  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    s3_bucket = aws_s3_bucket.app.id
    app_port  = var.app_port
    region    = var.aws_region
  })

  tags = {
    Name = "${var.project_name}-minikube"
  }

  # Wait for user_data to finish (cloud-init)
  # ALB health check will handle readiness
  depends_on = [
    aws_s3_object.index_html,
    aws_s3_object.video_1,
    aws_s3_object.video_2
  ]
}

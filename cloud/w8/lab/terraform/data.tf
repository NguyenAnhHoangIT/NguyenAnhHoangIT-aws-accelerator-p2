# ─────────────────────────────────────────────────────────────
# Data Sources — AMI Lookup + Availability Zones
# ─────────────────────────────────────────────────────────────

# Fetch available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Latest Ubuntu 22.04 LTS AMI from Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

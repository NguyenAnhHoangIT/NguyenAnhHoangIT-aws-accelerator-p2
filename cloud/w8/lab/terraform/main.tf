# ─────────────────────────────────────────────────────────────
# Disc Player — Terraform Configuration
# Providers: aws (infrastructure) + tls (SSH key generation)
# ─────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5"

  required_providers {
    # Provider #1 — AWS: all cloud infrastructure
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Provider #2 — TLS: generate SSH key pair
    # Wired into aws_key_pair for EC2 access
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ── AWS Provider ──────────────────────────────────────────────
provider "aws" {
  region = var.aws_region
}

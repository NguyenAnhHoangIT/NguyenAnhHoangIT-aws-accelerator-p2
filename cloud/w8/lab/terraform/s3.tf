# ─────────────────────────────────────────────────────────────
# S3 Bucket — Upload app files for EC2 to pull
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "app" {
  bucket_prefix = "${var.project_name}-app-"
  force_destroy = true # Allow terraform destroy to clean up

  tags = {
    Name = "${var.project_name}-app-bucket"
  }
}

# Block public access (EC2 accesses via IAM role)
resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Upload: index.html ───────────────────────────────────────
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.app.id
  key          = "index.html"
  source       = "${path.module}/../index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../index.html")
}

# ── Upload: assets/video 1 (480p) ────────────────────────────
resource "aws_s3_object" "video_1" {
  bucket       = aws_s3_bucket.app.id
  key          = "assets/YTDown_YouTube_An-Do-Mixi-Na-Na-Na-Na-Anh-Do-Mixi_Media_PD61lIYrG-M_001_480p.mp4"
  source       = "${path.module}/../assets/YTDown_YouTube_An-Do-Mixi-Na-Na-Na-Na-Anh-Do-Mixi_Media_PD61lIYrG-M_001_480p.mp4"
  content_type = "video/mp4"
  etag         = filemd5("${path.module}/../assets/YTDown_YouTube_An-Do-Mixi-Na-Na-Na-Na-Anh-Do-Mixi_Media_PD61lIYrG-M_001_480p.mp4")
}

# ── Upload: assets/video 2 (1080p) ───────────────────────────
resource "aws_s3_object" "video_2" {
  bucket       = aws_s3_bucket.app.id
  key          = "assets/YTDown_YouTube_Rick-Astley-Never-Gonna-Give-You-Up-Offi_Media_dQw4w9WgXcQ_001_1080p.mp4"
  source       = "${path.module}/../assets/YTDown_YouTube_Rick-Astley-Never-Gonna-Give-You-Up-Offi_Media_dQw4w9WgXcQ_001_1080p.mp4"
  content_type = "video/mp4"
  etag         = filemd5("${path.module}/../assets/YTDown_YouTube_Rick-Astley-Never-Gonna-Give-You-Up-Offi_Media_dQw4w9WgXcQ_001_1080p.mp4")
}

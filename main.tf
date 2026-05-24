resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "resume" {
  bucket = "${var.bucket_name_prefix}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_public_access_block" "resume" {
  bucket = aws_s3_bucket.resume.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "resume" {
  bucket = aws_s3_bucket.resume.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "resume_file" {
  bucket       = aws_s3_bucket.resume.id
  key          = var.resume_object_key
  source       = var.resume_file_path
  content_type = "application/pdf"
  etag         = filemd5(var.resume_file_path)
}

resource "aws_cloudfront_origin_access_control" "resume" {
  name                              = "resume-oac-${random_id.suffix.hex}"
  description                       = "OAC for resume bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "resume" {
  enabled             = true
  comment             = "Resume site"
  default_root_object = var.resume_object_key

  origin {
    domain_name              = aws_s3_bucket.resume.bucket_regional_domain_name
    origin_id                = "resume-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.resume.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "resume-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
resource "aws_s3_bucket_policy" "resume" {
  bucket = aws_s3_bucket.resume.id
  policy = data.aws_iam_policy_document.resume_bucket_policy.json
}

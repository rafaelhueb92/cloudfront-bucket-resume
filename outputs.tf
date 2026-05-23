output "bucket_name" {
  value = aws_s3_bucket.resume.bucket
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.resume.domain_name
}

output "resume_url" {
  value = "https://${aws_cloudfront_distribution.resume.domain_name}/${var.resume_object_key}"
}

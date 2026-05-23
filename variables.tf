variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
  default     = "us-east-1"
}

variable "bucket_name_prefix" {
  type        = string
  description = "Prefix used for S3 bucket name"
  default     = "resume-site"
}

variable "resume_object_key" {
  type        = string
  description = "Object key for the resume file in S3"
  default     = "rafael_cv_052026.pdf"
}

variable "resume_file_path" {
  type        = string
  description = "Local path to your resume file to upload"
  default     = "rafael_cv_052026.pdf"
}

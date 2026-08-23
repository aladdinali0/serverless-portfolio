variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name for website"
  type        = string
  default     = "aladdin-demo-58523"   # This must match the bucket in main.tf
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "aladdin-tf-state-0819"     
    key            = "static-site/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# ------------------------------------------------------------------
# STORAGE LAYER
# ------------------------------------------------------------------

resource "aws_s3_bucket" "site_bucket" {
  bucket = "aladdin-demo-58523"   
}

resource "aws_s3_bucket_public_access_block" "site_bucket_block" {
  bucket = aws_s3_bucket.site_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------
# ORIGIN ACCESS CONTROL
# ------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "site_oac" {
  name                              = "site-oac"
  description                       = "OAC for static site origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ------------------------------------------------------------------
# DELIVERY LAYER (CloudFront)
# ------------------------------------------------------------------

resource "aws_cloudfront_distribution" "site_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static site distribution"
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.site_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.site_bucket.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
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

# ------------------------------------------------------------------
# SECURITY LAYER (Bucket Policy)
# ------------------------------------------------------------------

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "site_bucket_policy" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.site_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.site_distribution.id}"
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------
# DATABASE LAYER
# ------------------------------------------------------------------

resource "aws_dynamodb_table" "visitor_counter" {
  name           = "VisitorCount"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# ------------------------------------------------------------------
# COMPUTE LAYER (Lambda)
# ------------------------------------------------------------------

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "visitor_counter" {
  filename          = data.archive_file.lambda_zip.output_path
  function_name     = "visitor-counter"
  role              = aws_iam_role.lambda_execution_role.arn
  handler           = "lambda_function.lambda_handler"
  runtime           = "python3.12"
  source_code_hash  = filebase64sha256(data.archive_file.lambda_zip.output_path)
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "dynamodb_access" {
  name = "lambda-dynamodb-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.visitor_counter.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# ------------------------------------------------------------------
# API LAYER
# ------------------------------------------------------------------

resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "visitor-api"
  protocol_type = "HTTP"
  target        = aws_lambda_function.visitor_counter.invoke_arn
}

resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.visitor_api.id
  name        = "dev"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}

# ------------------------------------------------------------------
# OUTPUTS
# ------------------------------------------------------------------

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.site_distribution.domain_name}"
}

output "api_endpoint" {
  value = "${aws_apigatewayv2_api.visitor_api.api_endpoint}/dev/visitor-count"
} 
# ------------------------------------------------------------------
# OBSERVABILITY LAYER (CloudWatch + SNS Alerts)
# ------------------------------------------------------------------

# SNS Topic for email alerts
resource "aws_sns_topic" "alert_topic" {
  name = "lambda-error-alerts"
}

# SNS Email Subscription (CHANGE THIS TO YOUR EMAIL)
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alert_topic.arn
  protocol  = "email"
  endpoint  = "aladdinali0@gmail.com"   # 
}

# CloudWatch Alarm - Triggers if Lambda has ANY errors
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "visitor-counter-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Lambda function has errors"
  alarm_actions       = [aws_sns_topic.alert_topic.arn]

  dimensions = {
    FunctionName = aws_lambda_function.visitor_counter.function_name
  }
}

# CloudWatch Dashboard (Graphical view of your metrics)
resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "Serverless-Infrastructure"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum" }],
            ["AWS/Lambda", "Errors", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Lambda Performance (Invocations vs Errors)"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/DynamoDB", "SuccessfulRequestLatency", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "DynamoDB Latency"
        }
      }
    ]
  })
}
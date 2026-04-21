# --- DynamoDB Table for translation history ---
resource "aws_dynamodb_table" "demo-translations" {
  name         = "${local.prefix}-translations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "translationId"

  attribute {
    name = "translationId"
    type = "S"
  }
}

# --- S3 Bucket for static website ---
resource "aws_s3_bucket" "demo-website" {
  bucket        = "${local.prefix}-website-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "demo-website" {
  bucket                  = aws_s3_bucket.demo-website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "demo-website" {
  bucket = aws_s3_bucket.demo-website.id

  index_document {
    suffix = "index.html"
  }
}

# --- CloudFront Distribution ---
resource "aws_cloudfront_origin_access_control" "demo-website" {
  name                              = "${local.prefix}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "demo-website" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.demo-website.bucket_regional_domain_name
    origin_id                = "s3-website"
    origin_access_control_id = aws_cloudfront_origin_access_control.demo-website.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-website"
    viewer_protocol_policy = "redirect-to-https"

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

resource "aws_s3_bucket_policy" "demo-website" {
  bucket = aws_s3_bucket.demo-website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.demo-website.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.demo-website.arn
        }
      }
    }]
  })
}

# --- Lambda: Translator API ---
resource "aws_iam_role" "demo-translator" {
  name = "${local.prefix}-translator"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "demo-translator" {
  name = "${local.prefix}-translator"
  role = aws_iam_role.demo-translator.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:Scan"]
        Resource = aws_dynamodb_table.demo-translations.arn
      },
      {
        Effect = "Allow"
        Action = ["bedrock:InvokeModel"]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/${local.bedrock_model_id}",
          "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${local.bedrock_inference_profile_id}"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

data "archive_file" "translator" {
  type        = "zip"
  source_file = "${path.module}/lambda/translator.py"
  output_path = "${path.module}/lambda/translator.zip"
}

resource "aws_lambda_function" "demo-translator" {
  function_name                  = "${local.prefix}-translator"
  role                           = aws_iam_role.demo-translator.arn
  handler                        = "translator.handler"
  runtime                        = "python3.12"
  timeout                        = 30
  reserved_concurrent_executions = 10
  filename                       = data.archive_file.translator.output_path
  source_code_hash               = data.archive_file.translator.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.demo-translations.name
      MODEL_ID   = local.bedrock_inference_profile_id
    }
  }
}

# --- API Gateway ---
resource "aws_apigatewayv2_api" "demo-translator" {
  name          = "${local.prefix}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }
}

resource "aws_apigatewayv2_stage" "demo-translator" {
  api_id      = aws_apigatewayv2_api.demo-translator.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.demo-api-access.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_apigatewayv2_integration" "demo-translator" {
  api_id                 = aws_apigatewayv2_api.demo-translator.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.demo-translator.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "demo-translate" {
  api_id    = aws_apigatewayv2_api.demo-translator.id
  route_key = "POST /translate"
  target    = "integrations/${aws_apigatewayv2_integration.demo-translator.id}"
}

resource "aws_apigatewayv2_route" "demo-history" {
  api_id    = aws_apigatewayv2_api.demo-translator.id
  route_key = "GET /history"
  target    = "integrations/${aws_apigatewayv2_integration.demo-translator.id}"
}

resource "aws_lambda_permission" "demo-apigw" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo-translator.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.demo-translator.execution_arn}/*/*"
}

# --- CloudWatch Logs ---
resource "aws_cloudwatch_log_group" "demo-api-access" {
  name              = "/apigateway/${local.prefix}-api"
  retention_in_days = 7
}

# --- CloudWatch Alarms ---
resource "aws_cloudwatch_metric_alarm" "demo-lambda-errors" {
  alarm_name          = "${local.prefix}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Lambda translator errors detected"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.demo-translator.function_name
  }
}

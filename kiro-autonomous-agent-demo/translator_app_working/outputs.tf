output "website_url" {
  description = "CloudFront URL for the web application"
  value       = "https://${aws_cloudfront_distribution.demo-website.domain_name}"
}

output "api_url" {
  description = "API Gateway URL for the translator API"
  value       = aws_apigatewayv2_api.demo-translator.api_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name for monitoring"
  value       = aws_lambda_function.demo-translator.function_name
}

output "dynamodb_table" {
  description = "DynamoDB table name for translation history"
  value       = aws_dynamodb_table.demo-translations.name
}

output "s3_bucket" {
  description = "S3 bucket name for static website"
  value       = aws_s3_bucket.demo-website.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = aws_cloudfront_distribution.demo-website.id
}

output "bedrock_model_id" {
  description = "Bedrock model ID used for translation (dynamically resolved)"
  value       = local.bedrock_model_id
}

output "bedrock_inference_profile_id" {
  description = "Bedrock inference profile ID used for invocation"
  value       = local.bedrock_inference_profile_id
}

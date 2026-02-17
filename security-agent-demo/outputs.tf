output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.demo-notes.api_endpoint
}

output "custom_domain_url" {
  description = "Custom domain URL for the API"
  value       = "https://${var.domain_name}"
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.demo-notes-api.function_name
}

output "dynamodb_table" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.demo-notes.name
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.demo-notes.id
}

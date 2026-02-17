output "sns_topic_arn" {
  description = "SNS topic ARN for publishing test orders"
  value       = aws_sns_topic.demo-orders.arn
}

output "lambda_function_name" {
  description = "Lambda function name for monitoring"
  value       = aws_lambda_function.demo-order-processor.function_name
}

output "lambda_role_name" {
  description = "Lambda IAM role name - used for fault injection"
  value       = aws_iam_role.demo-order-processor.name
}

output "lambda_role_policy_name" {
  description = "Lambda IAM policy name - used for fault injection"
  value       = aws_iam_role_policy.demo-order-processor.name
}

output "s3_bucket" {
  description = "S3 bucket for order receipts"
  value       = aws_s3_bucket.demo-receipts.id
}

output "dynamodb_table" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.demo-orders.name
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.demo-order-processing.url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.demo-frontend.name
}

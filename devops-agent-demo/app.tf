# --- SNS Topic for order notifications ---
resource "aws_sns_topic" "demo-orders" {
  name = "${local.prefix}-orders"
}

# --- SQS Queue for order processing ---
resource "aws_sqs_queue" "demo-order-processing" {
  name                       = "${local.prefix}-order-processing"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
  sqs_managed_sse_enabled    = true
}

resource "aws_sns_topic_subscription" "demo-sqs-sub" {
  topic_arn = aws_sns_topic.demo-orders.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.demo-order-processing.arn
}

resource "aws_sqs_queue_policy" "demo-order-processing" {
  queue_url = aws_sqs_queue.demo-order-processing.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.demo-order-processing.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.demo-orders.arn }
      }
    }]
  })
}

# --- DynamoDB Table ---
resource "aws_dynamodb_table" "demo-orders" {
  name         = "${local.prefix}-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "orderId"

  attribute {
    name = "orderId"
    type = "S"
  }
}

# --- S3 Bucket for order receipts ---
resource "aws_s3_bucket" "demo-receipts" {
  bucket        = "${local.prefix}-receipts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "demo-receipts" {
  bucket                  = aws_s3_bucket.demo-receipts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Lambda: Order Processor (reads SQS, writes DynamoDB + S3) ---
resource "aws_iam_role" "demo-order-processor" {
  name = "${local.prefix}-order-processor"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "demo-order-processor" {
  name = "${local.prefix}-order-processor"
  role = aws_iam_role.demo-order-processor.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.demo-order-processing.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.demo-orders.arn
      },
      {
        # This is the permission we will REMOVE to inject the fault
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.demo-receipts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

data "archive_file" "order-processor" {
  type        = "zip"
  source_file = "${path.module}/lambda/order_processor.py"
  output_path = "${path.module}/lambda/order_processor.zip"
}

resource "aws_lambda_function" "demo-order-processor" {
  function_name        = "${local.prefix}-order-processor"
  role                 = aws_iam_role.demo-order-processor.arn
  handler              = "order_processor.handler"
  runtime              = "python3.12"
  timeout              = 30
  reserved_concurrent_executions = 10
  filename             = data.archive_file.order-processor.output_path
  source_code_hash     = data.archive_file.order-processor.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.demo-orders.name
      BUCKET_NAME = aws_s3_bucket.demo-receipts.id
    }
  }
}

resource "aws_lambda_event_source_mapping" "demo-sqs-trigger" {
  event_source_arn = aws_sqs_queue.demo-order-processing.arn
  function_name    = aws_lambda_function.demo-order-processor.arn
  batch_size       = 5
}

# --- ECS Frontend (simple order submission service) ---
resource "aws_cloudwatch_log_group" "demo-frontend" {
  name              = "/ecs/${local.prefix}-frontend"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "demo-frontend" {
  name = "${local.prefix}-frontend"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_iam_role" "demo-ecs-task-execution" {
  name = "${local.prefix}-ecs-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "demo-ecs-task-execution" {
  role       = aws_iam_role.demo-ecs-task-execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "demo-ecs-task" {
  name = "${local.prefix}-ecs-task"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "demo-ecs-task" {
  name = "${local.prefix}-ecs-task"
  role = aws_iam_role.demo-ecs-task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = aws_sns_topic.demo-orders.arn
    }]
  })
}

resource "aws_ecs_task_definition" "demo-frontend" {
  family                   = "${local.prefix}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.demo-ecs-task-execution.arn
  task_role_arn            = aws_iam_role.demo-ecs-task.arn

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = "amazon/amazon-ecs-sample"
    essential = true
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
    environment = [
      { name = "SNS_TOPIC_ARN", value = aws_sns_topic.demo-orders.arn }
    ]
    readonlyRootFilesystem = true
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.demo-frontend.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "frontend"
      }
    }
  }])
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
  alarm_description   = "Lambda order processor errors detected"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.demo-order-processor.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "demo-sqs-age" {
  alarm_name          = "${local.prefix}-sqs-message-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 300
  alarm_description   = "SQS messages aging - possible processing failure"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.demo-order-processing.name
  }
}

# --- DynamoDB Table ---
resource "aws_dynamodb_table" "demo-notes" {
  name         = "${local.prefix}-notes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "noteId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "noteId"
    type = "S"
  }
}

# --- Lambda: Notes API (intentionally vulnerable) ---
resource "aws_iam_role" "demo-notes-api" {
  name = "${local.prefix}-notes-api"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "demo-notes-api" {
  name = "${local.prefix}-notes-api"
  role = aws_iam_role.demo-notes-api.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Query", "dynamodb:DeleteItem", "dynamodb:Scan"]
        Resource = aws_dynamodb_table.demo-notes.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

data "archive_file" "notes-api" {
  type        = "zip"
  source_file = "${path.module}/lambda/notes_api.py"
  output_path = "${path.module}/lambda/notes_api.zip"
}

resource "aws_lambda_function" "demo-notes-api" {
  function_name                  = "${local.prefix}-notes-api"
  role                           = aws_iam_role.demo-notes-api.arn
  handler                        = "notes_api.handler"
  runtime                        = "python3.12"
  timeout                        = 30
  reserved_concurrent_executions = 10
  filename                       = data.archive_file.notes-api.output_path
  source_code_hash               = data.archive_file.notes-api.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.demo-notes.name
    }
  }
}

# --- API Gateway (Regional) ---
resource "aws_apigatewayv2_api" "demo-notes" {
  name          = "${local.prefix}-notes-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "demo-notes" {
  api_id      = aws_apigatewayv2_api.demo-notes.id
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

resource "aws_apigatewayv2_integration" "demo-notes" {
  api_id                 = aws_apigatewayv2_api.demo-notes.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.demo-notes-api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "demo-catch-all" {
  api_id    = aws_apigatewayv2_api.demo-notes.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.demo-notes.id}"
}

resource "aws_lambda_permission" "demo-apigw" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo-notes-api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.demo-notes.execution_arn}/*/*"
}

# --- Custom Domain (Regional) ---
resource "aws_apigatewayv2_domain_name" "demo-notes" {
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.demo.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "demo-notes" {
  api_id      = aws_apigatewayv2_api.demo-notes.id
  domain_name = aws_apigatewayv2_domain_name.demo-notes.id
  stage       = aws_apigatewayv2_stage.demo-notes.id
}

resource "aws_route53_record" "demo-api" {
  zone_id = data.aws_route53_zone.demo.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.demo-notes.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.demo-notes.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# --- CloudWatch Logs ---
resource "aws_cloudwatch_log_group" "demo-api-access" {
  name              = "/apigateway/${local.prefix}-notes-api"
  retention_in_days = 7
}

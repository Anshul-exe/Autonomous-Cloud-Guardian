resource "aws_iam_role" "lambda_role" {
  name = "cloud-guardian-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "cloud-guardian-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:DescribeAlarms"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "stop_idle_instances" {
  filename         = "../lambda/lambda_function.zip"
  function_name    = "cloud-guardian-stop-idle"
  role             = aws_iam_role.lambda_role.arn
  handler          = "stop_idle_instances.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/lambda_function.zip")
  runtime          = "python3.9"
  timeout          = 60

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      CPU_THRESHOLD     = "5.0"
    }
  }
}

# CloudWatch Event Rule (trigger every hour)
resource "aws_cloudwatch_event_rule" "hourly" {
  name                = "cloud-guardian-hourly-check"
  description         = "Trigger Lambda every hour to check idle instances"
  schedule_expression = "rate(1 hour)"
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.hourly.name
  target_id = "cloud-guardian-lambda"
  arn       = aws_lambda_function.stop_idle_instances.arn
}

# Lambda Permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_idle_instances.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.hourly.arn
}

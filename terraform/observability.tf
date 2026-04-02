# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/cloud-guardian/app"
  retention_in_days = 7

  tags = {
    Project   = "cloud-guardian"
    ManagedBy = "terraform"
  }
}

# Log Processor Lambda Function
resource "aws_lambda_function" "log_processor" {
  filename         = "../lambda/log_processor.zip"
  function_name    = "cloud-guardian-log-processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "log_processor.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/log_processor.zip")
  runtime          = "python3.9"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  tags = {
    Project   = "cloud-guardian"
    ManagedBy = "terraform"
  }
}

# Permission for CloudWatch Logs to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_logs" {
  statement_id  = "AllowCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_processor.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.app_logs.arn}:*"
}

# Subscription filter - triggers Lambda on ERROR/FATAL/Exception logs
resource "aws_cloudwatch_log_subscription_filter" "error_filter" {
  name            = "cloud-guardian-error-filter"
  log_group_name  = aws_cloudwatch_log_group.app_logs.name
  filter_pattern  = "?ERROR ?FATAL ?Exception ?CRITICAL"
  destination_arn = aws_lambda_function.log_processor.arn

  depends_on = [aws_lambda_permission.allow_cloudwatch_logs]
}

# CloudWatch Dashboard (Free: first 3 dashboards)
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "cloud-guardian"

  dashboard_body = jsonencode({
    widgets = [
      # Row 1: EC2 Metrics
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "EC2 CPU Utilization"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.cloud_guardian.id, { label = "cloud-guardian-app" }]
          ]
          period = 300
          stat   = "Average"
          yAxis  = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "EC2 Network Traffic"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.cloud_guardian.id, { label = "In" }],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.cloud_guardian.id, { label = "Out" }]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "EC2 Status Checks"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.cloud_guardian.id]
          ]
          period = 300
          stat   = "Maximum"
        }
      },
      # Row 2: Lambda Metrics
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "Lambda Invocations"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "cloud-guardian-stop-idle", { label = "stop-idle" }],
            ["AWS/Lambda", "Invocations", "FunctionName", "cloud-guardian-log-processor", { label = "log-processor" }]
          ]
          period = 3600
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "Lambda Errors"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", "cloud-guardian-stop-idle", { label = "stop-idle" }],
            ["AWS/Lambda", "Errors", "FunctionName", "cloud-guardian-log-processor", { label = "log-processor" }]
          ]
          period = 3600
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "Lambda Duration"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "cloud-guardian-stop-idle", { label = "stop-idle (ms)" }],
            ["AWS/Lambda", "Duration", "FunctionName", "cloud-guardian-log-processor", { label = "log-processor (ms)" }]
          ]
          period = 3600
          stat   = "Average"
        }
      },
      # Row 3: Logs
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          title  = "Recent Application Errors"
          region = var.aws_region
          query  = "SOURCE '/cloud-guardian/app' | filter @message like /ERROR|FATAL|Exception/ | sort @timestamp desc | limit 20"
        }
      }
    ]
  })
}

# Output dashboard URL
output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=cloud-guardian"
}

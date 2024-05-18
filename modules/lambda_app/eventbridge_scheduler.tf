# IAM role for EventBridge scheduler
data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "scheduler_role" {
  name               = "${local.name}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
}

# IAM policy for EventBridge scheduler to invoke Lambda function
data "aws_iam_policy_document" "invoke_lambda" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.lambda_func.arn]
  }
}

resource "aws_iam_policy" "invoke_lambda" {
  name   = "${local.name}-invoke-lambda"
  policy = data.aws_iam_policy_document.invoke_lambda.json
}

resource "aws_iam_role_policy_attachment" "scheduler_lambda" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.invoke_lambda.arn
}

# EventBridge scheduler
resource "aws_scheduler_schedule" "cron_scheduler" {
  name                = local.name
  schedule_expression = "cron(${local.cron})"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    role_arn = aws_iam_role.scheduler_role.arn
    arn      = aws_lambda_function.lambda_func.arn
  }
}

# OLD WAY: CloudWatch Events
# resource "aws_lambda_permission" "event_lambda" {
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda_func.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.cron_event.arn
# }

# resource "aws_cloudwatch_event_rule" "cron_event" {
#   name                = local.name
#   schedule_expression = "cron(${local.cron})"
# }

# resource "aws_cloudwatch_event_target" "event_lambda" {
#   rule = aws_cloudwatch_event_rule.cron_event.name
#   arn  = aws_lambda_function.lambda_func.arn
# }

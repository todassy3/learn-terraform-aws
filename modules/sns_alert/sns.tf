# SNS topic
resource "aws_sns_topic" "sns_alert" {
  name = local.name
}

# SNS email subscription
resource "aws_sns_topic_subscription" "sns_email" {
  topic_arn = aws_sns_topic.sns_alert.arn
  protocol  = "email"
  endpoint  = var.email
}

# SNS slack subscription via Lambda function
resource "aws_lambda_permission" "sns_slack" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_func.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_alert.arn
}

resource "aws_sns_topic_subscription" "sns_slack" {
  topic_arn = aws_sns_topic.sns_alert.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_func.arn
}

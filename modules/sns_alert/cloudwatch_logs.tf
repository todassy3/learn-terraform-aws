# IAM policy for Lambda function to write logs
data "aws_iam_policy_document" "logs_access" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "logs_access" {
  name   = "${local.name}-logs-access"
  policy = data.aws_iam_policy_document.logs_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.logs_access.arn
}

# CloudWatch Logs group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 30
}

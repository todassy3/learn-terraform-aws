# IAM policy for Lambda function to write to SNS topic
data "aws_iam_policy_document" "sns_access" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_alert_topic_arn]
  }
}

resource "aws_iam_policy" "sns_access" {
  name   = "${local.name}-sns-access"
  policy = data.aws_iam_policy_document.sns_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_sns" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sns_access.arn
}

# IAM policy for Lambda function to access DynamoDB table
data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:GetItem"]
    resources = [aws_dynamodb_table.user_table.arn]
  }
}

resource "aws_iam_policy" "dynamodb_access" {
  name   = "${local.name}-dynamodb-access"
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# DynamoDB table
resource "aws_dynamodb_table" "user_table" {
  name         = "${local.name}-user"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "N"
  }

  /*
  lifecycle {
    prevent_destroy = true
  }
  */
}

resource "aws_dynamodb_table_item" "user_table_item" {
  table_name = aws_dynamodb_table.user_table.name
  hash_key   = aws_dynamodb_table.user_table.hash_key

  item = jsonencode({
    user_id = {
      N = "1"
    },
    user_name = {
      S = "Taro"
    },
  })
}

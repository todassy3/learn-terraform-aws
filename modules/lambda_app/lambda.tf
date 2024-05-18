# IAM role for Lambda function
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Lambda layer
resource "null_resource" "lambda_layer" {
  triggers = {
    requirements_diff = filebase64("${path.module}/src/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<-EOF
      python3 -c 'import sys; assert sys.version_info[:2] == tuple(map(int, "${local.runtime}"[6:].split(".")))' &&
      rm -rf ${path.module}/out/layer &&
      python3 -m venv ${path.module}/out/venv &&
      ${path.module}/out/venv/bin/pip3 install -r ${path.module}/src/requirements.txt -t ${path.module}/out/layer/python --no-cache-dir
    EOF

    on_failure = fail
  }
}

data "archive_file" "lambda_layer" {
  depends_on = [null_resource.lambda_layer]

  type        = "zip"
  source_dir  = "${path.module}/out/layer"
  output_path = "${path.module}/out/lambda_layer.zip"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name          = "${local.name}-dependencies"
  filename            = data.archive_file.lambda_layer.output_path
  source_code_hash    = data.archive_file.lambda_layer.output_base64sha256
  compatible_runtimes = [local.runtime]
}

# Lambda function
data "archive_file" "lambda_func" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/out/lambda_func.zip"
}

resource "aws_lambda_function" "lambda_func" {
  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group,
    aws_iam_role_policy_attachment.lambda_logs,
    aws_dynamodb_table.user_table,
    aws_dynamodb_table_item.user_table_item,
    aws_iam_role_policy_attachment.lambda_dynamodb,
    aws_iam_role_policy_attachment.lambda_sns,
  ]

  function_name    = local.name
  filename         = data.archive_file.lambda_func.output_path
  source_code_hash = data.archive_file.lambda_func.output_base64sha256
  runtime          = local.runtime
  handler          = "main.handler"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  timeout          = 60
  memory_size      = 128
  role             = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      SLACK_TOKEN   = var.slack_token
      SLACK_CHANNEL = var.slack_channel
      TABLE_NAME    = aws_dynamodb_table.user_table.name
    }
  }

  dead_letter_config {
    target_arn = var.sns_alert_topic_arn
  }
}

resource "null_resource" "destroy" {
  provisioner "local-exec" {
    when       = destroy
    command    = "rm -rf ${path.module}/out"
    on_failure = continue
  }
}

# Publish Lambda function errors to SNS topic
resource "aws_lambda_function_event_invoke_config" "lambda_sns" {
  function_name = aws_lambda_function.lambda_func.function_name

  destination_config {
    on_failure {
      destination = var.sns_alert_topic_arn
    }
  }
}

# Test invocation
data "aws_lambda_invocation" "test" {
  depends_on = [aws_lambda_function.lambda_func]

  function_name = aws_lambda_function.lambda_func.function_name
  input         = jsonencode({})
}

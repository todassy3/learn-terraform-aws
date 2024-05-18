output "lambda_test_result" {
  value = jsondecode(data.aws_lambda_invocation.test.result)
}

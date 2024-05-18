locals {
  name    = "example-lambda-app"
  runtime = "python3.12"
  cron    = "0/5 * * * ? *"
}

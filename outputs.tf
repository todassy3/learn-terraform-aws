output "instance_id" {
  value = module.ec2_app.instance_id
}

output "instance_public_ip" {
  value = module.ec2_app.instance_public_ip
}

output "lambda_test_result" {
  value = module.lambda_app.lambda_test_result
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.32"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-northeast-1"
}

module "ec2_app" {
  source = "./modules/ec2_app"
}

module "sns_alert" {
  source        = "./modules/sns_alert"
  slack_token   = var.slack_token
  slack_channel = var.slack_channel
  email         = var.email
}

module "lambda_app" {
  depends_on          = [module.sns_alert]
  source              = "./modules/lambda_app"
  slack_token         = var.slack_token
  slack_channel       = var.slack_channel
  sns_alert_topic_arn = module.sns_alert.sns_alert_topic_arn
}

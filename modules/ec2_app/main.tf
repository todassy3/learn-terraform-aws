locals {
  name = "example-ec2-app"
}

resource "aws_instance" "app_server" {
  ami           = "ami-02a405b3302affc24"
  instance_type = "t2.micro"

  tags = {
    Name = local.name
  }
}

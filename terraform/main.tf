// ------------------------------------------------------
// Providers
// ------------------------------------------------------
provider "aws" {
  region = "eu-west-1"
}


// ------------------------------------------------------
// Terraform Remote State on S3
// ------------------------------------------------------

terraform {
  backend "s3" {
    bucket = "khajour-s3"
    key = "webapp/terraform.tfstate"
    region = "eu-west-1"
  }
}


data "terraform_remote_state" "rs-vpc" {
  backend = "s3"
  config = {
    region = "eu-west-1"
    bucket = "khajour-s3"
    key = "vpc/terraform.tfstate"
  }
}
// ------------------------------------------------------
// EC2 Instances
// ------------------------------------------------------
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "vpc-745e0113"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }


  tags {
    Name = "training-web-app-sg"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/app_install.tpl")}"
  vars {
    username = "Abdelaziz"
  }
}

resource "aws_instance" "web-app" {
  ami           = "ami-acd005d5"
  instance_type = "t2.medium"
  subnet_id     = "subnet-a8763fcf"
  key_name = "terraform-key-pair"
  associate_public_ip_address = "true"
  user_data = "${data.template_file.user_data.rendered}"
  security_groups = ["${aws_security_group.allow_all.id}"]


  tags {
    Name = "terraform web-app"
  }
}

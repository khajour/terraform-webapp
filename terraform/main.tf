
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
// Security group
// ------------------------------------------------------
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${data.terraform_remote_state.rs-vpc.vpc_id}"



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


// ------------------------------------------------------
// EC2 Instance
// ------------------------------------------------------

data "template_file" "user_data" {
  template = "${file("${path.module}/app_install.tpl")}"
  vars {
    username = "Abdelaziz"
  }
}

resource "aws_instance" "web-app" {
  count = 2
  ami           = "ami-acd005d5"
  instance_type = "t2.medium"
  subnet_id     = "${element(data.terraform_remote_state.rs-vpc.public_subnet_ids, count.index)}"


  key_name = "terraform-key-pair"
  associate_public_ip_address = "true"
  user_data = "${data.template_file.user_data.rendered}"
  security_groups = ["${aws_security_group.allow_all.id}"]


  tags {
    Name = "terraform web-app"
  }
}

// ------------------------------------------------------
// ELB
// ------------------------------------------------------
resource "aws_elb" "webapp-elb" {
  name               = "webapp-elb"
  subnets            = ["${data.terraform_remote_state.rs-vpc.public_subnet_ids}"]
  security_groups    = ["${aws_security_group.allow_all.id}"]


  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 5
  }

  instances             = ["${aws_instance.web-app.*.id}"]



  tags {
    Name = "terraform-elb"
  }
}

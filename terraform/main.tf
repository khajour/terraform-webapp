// ------------------------------------------------------
// Providers
// ------------------------------------------------------
provider "aws" {
  region = "eu-west-1"
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
    protocol    = "HTTP"
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

resource "template_file" "user_data" {
  template = "app_install.tpl"
}


resource "aws_instance" "web-app" {
  ami           = "ami-acd005d5"
  instance_type = "t2.medium"
  subnet_id     = "subnet-a8763fcf"
  key_name = "terraform-key-pair"
  associate_public_ip_address = "true"
  user_data = "${template_file.user_data.rendered}"
  security_groups = ["${aws_security_group.allow_all.id}"]


  tags {
    Name = "terraform web-app"
  }
}

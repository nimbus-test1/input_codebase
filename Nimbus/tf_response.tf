
Terraform configuration content
```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0" # Ubuntu Server 20.04 LTS (HVM)
  instance_type = "t2.micro"
  key_name      = var.key_name
  security_groups = [aws_security_group.web_sg.name]

  tags = {
    Name = "Web Server"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "web_eip" {
  instance = aws_instance.web_server.id
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}
```

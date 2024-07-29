
```hcl
# Terraform configuration content
provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key-pair"

  security_groups = [aws_security_group.web_server_sg.name]

  tags = {
    Name = "WebServer"
  }
}

resource "aws_security_group" "web_server_sg" {
  name        = "WebServerSG"
  description = "Enable HTTP and SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "web_server_eip" {
  instance = aws_instance.web_server.id
}
```

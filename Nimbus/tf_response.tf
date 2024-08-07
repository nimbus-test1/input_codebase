
```hcl
provider "aws" {
  region = var.region
}

resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  backup_window        = "03:00-04:00"
  backup_retention_period = 7
  skip_final_snapshot  = true
}

variable "region" {
  description = "AWS region to deploy the MySQL instance"
  type        = string
  default     = "us-west-2"
}

variable "db_name" {
  description = "The name of the MySQL database"
  type        = string
  default     = "mydatabase"
}

variable "db_username" {
  description = "The username for the MySQL database"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "The password for the MySQL database"
  type        = string
  default     = "password"
}
```


```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_db_instance" "mysql_instance" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = var.db_name
  username             = var.db_user
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true

  backup_retention_period = 7
  backup_window           = "07:00-09:00"
}

variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "my_database"
}

variable "db_user" {
  description = "The username for the database"
  type        = string
  default     = "my_user"
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  default     = "my_password"
}

output "db_instance_endpoint" {
  description = "The endpoint of the MySQL instance"
  value       = aws_db_instance.mysql_instance.endpoint
}
```

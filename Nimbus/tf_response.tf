
```hcl
provider "aws" {
  region = var.aws_region
}

resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true

  backup_window             = var.backup_window
  backup_retention_period   = var.backup_retention_period
}

variable "aws_region" {
  description = "The AWS region to deploy the MySQL instance in"
  default     = "us-west-2"
}

variable "db_name" {
  description = "The name of the MySQL database"
  default     = "mydb"
}

variable "db_username" {
  description = "The username for the MySQL database"
  default     = "admin"
}

variable "db_password" {
  description = "The password for the MySQL database"
  default     = "password"
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled"
  default     = "04:00-06:00"
}

variable "backup_retention_period" {
  description = "The number of days to retain backups for"
  default     = 7
}
```

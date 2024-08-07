
```hcl
# main.tf
provider "aws" {
  region = "us-west-2"
}

resource "aws_db_instance" "my_mysql_db" {
  allocated_storage    = 20
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  engine_version       = "5.7"
  username             = "admin"
  password             = "password"
  db_name              = "mydatabase"
  backup_retention_period = 7
  backup_window        = "03:00-04:00"

  # Ensure the database is accessible
  publicly_accessible  = true

  tags = {
    Name = "MySQLInstance"
  }
}
```

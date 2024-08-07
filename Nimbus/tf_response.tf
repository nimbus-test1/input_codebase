
```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydatabase"
  username             = "myuser"
  password             = "mypassword"
  parameter_group_name = "default.mysql5.7"
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  publicly_accessible     = true
  skip_final_snapshot     = true

  tags = {
    Name = "MySQLInstance"
  }
}
```

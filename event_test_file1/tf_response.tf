
```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  backup_retention_period = 7
  backup_window        = "02:00-03:00"

  tags = {
    Name = "mysql-instance"
  }
}

resource "aws_s3_bucket" "mysql_backups" {
  bucket = "my-mysql-backups"
  acl    = "private"
}

resource "aws_s3_bucket_object" "backup_script" {
  bucket = aws_s3_bucket.mysql_backups.bucket
  key    = "scripts/backup.sh"
  source = "scripts/backup.sh"
  acl    = "private"
}

resource "aws_lambda_function" "backup_lambda" {
  function_name = "mysql_backup"
  handler       = "backup.handler"
  runtime       = "python3.8"
  role          = aws_iam_role.lambda_exec.arn
  s3_bucket     = aws_s3_bucket.mysql_backups.bucket
  s3_key        = "scripts/backup.sh"
  environment {
    variables = {
      DB_INSTANCE_IDENTIFIER = aws_db_instance.mysql.id
      S3_BUCKET              = aws_s3_bucket.mysql_backups.bucket
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

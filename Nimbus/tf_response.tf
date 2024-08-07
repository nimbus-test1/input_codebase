
```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "example-bucket-unique-name"
  acl    = "private"
}

output "bucket_name" {
  value = aws_s3_bucket.example_bucket.bucket
}
```

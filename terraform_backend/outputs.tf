output "terraform_state_bucket_name" {
  value       = aws_s3_bucket.terraform_state_bucket.bucket
  description = "The name of the Terraform state S3 bucket"
}

output "terraform_state_locktable_name" {
  value       = aws_dynamodb_table.terraform_state_locktable.name
  description = "The name of the Terraform state locktable"
}

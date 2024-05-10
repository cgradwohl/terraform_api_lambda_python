provider "aws" {
  region = var.aws_region
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "${var.state_bucket_name}-${random_string.bucket_suffix.result}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_state_locktable" {
  name           = var.state_locktable_name
  read_capacity  = var.state_locktable_read_capacity
  write_capacity = var.state_locktable_write_capacity
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# resource "aws_iam_policy" "terraform_backend_policy" {
#   name        = "TerraformBackendPolicy"
#   description = "Allows Terraform to manage S3 and DynamoDB for state storage and locking"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:ListBucket",
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject"
#         ],
#         Resource = [
#           "${aws_s3_bucket.terraform_state_bucket.arn}",
#           "${aws_s3_bucket.terraform_state_bucket.arn}/*"
#         ]
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "dynamodb:DescribeTable",
#           "dynamodb:GetItem",
#           "dynamodb:PutItem",
#           "dynamodb:DeleteItem"
#         ],
#         Resource = "${aws_dynamodb_table.terraform_state_locktable.arn}"
#       }
#     ]
#   })
# }

# resource "aws_iam_role" "terraform_backend_role" {
#   name = "TerraformBackendAccessRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Federated = "arn:aws:iam::${var.account}:oidc-provider/token.actions.githubusercontent.com"
#         },
#         Action = "sts:AssumeRole",
#         Condition = {
#           StringEquals = {
#             "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com",
#             "token.actions.githubusercontent.com:sub" : "repo:${var.github_username}/${var.github_repo_name}:*"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "terraform_backend_policy_attachment" {
#   role       = aws_iam_role.terraform_backend_role.name
#   policy_arn = aws_iam_policy.terraform_backend_policy.arn
# }




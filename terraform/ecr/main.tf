provider "aws" {
  region = var.aws_region
}


####
# ECR
####
resource "aws_ecr_repository" "sensor_rest_api_ecr_repo" {
  name = "sensor_rest_api_ecr_repo"
}

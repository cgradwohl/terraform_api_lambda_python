variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources."
  default     = "us-west-1"
}

variable "stage" {
  description = "The AWS API Gateway stage."
  default     = "dev"
}

variable "ecr_repository_url" {
  type        = string
  description = "The AWS ECR repository containing lambda image URI's."
}

variable "image_tag" {
  type        = string
  description = "The image tag for the Lambda's URI."
}


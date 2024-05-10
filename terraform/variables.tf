variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources."
  default     = "us-west-1"
}

variable "image_tag" {
  type = string
}

variable "stage" {
  description = "This is the environment where your webapp is deployed. qa, prod, or dev"
  default     = "dev"
}

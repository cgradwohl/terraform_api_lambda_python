variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources."
  default     = "us-west-1"
}

variable "state_bucket_name" {
  type        = string
  description = "The remote backend state bucket."
  default     = "dev-tfstate-bucket"
}

variable "state_locktable_name" {
  type        = string
  description = "The remote backend state lock table."
  default     = "dev-tfstate-locktable"
}

variable "state_locktable_read_capacity" {
  type        = number
  description = "The remote backend state lock table read capacity."
  default     = 1
}

variable "state_locktable_write_capacity" {
  type        = number
  description = "The remote backend state lock table write capacity."
  default     = 1
}

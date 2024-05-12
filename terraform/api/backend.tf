terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }
    }
    backend "s3" {
        bucket         = "dev-tfstate-bucket-evmcsb4i"
        key            = "dev/state/api/terraform.tfstate"
        region         = "us-west-1"
        dynamodb_table = "dev-tfstate-locktable"
        encrypt        = true
    }
}

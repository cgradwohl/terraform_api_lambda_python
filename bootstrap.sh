#!/bin/bash

# Ask for AWS profile or use default
# read -p "Enter AWS profile (press enter to use default): " AWS_PROFILE
# if [ -z "$AWS_PROFILE" ]; then
#   echo "Using default AWS profile"
#   AWS_PROFILE="default"
# fi

# Ask for AWS region or use default
read -p "Enter AWS region (press enter to use us-west-1): " AWS_REGION
if [ -z "$AWS_REGION" ]; then
  echo "Using us-west-1 region"
  AWS_REGION="us-west-1"
fi

# # Retrieve the AWS Account Number
# ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
# if [ $? -ne 0 ]; then
#   echo "Failed to retrieve AWS Account ID." 1>&2
#   exit 1
# fi

# # Retrieve the AWS Account Number
# IAM_USER=$(aws iam get-user --query 'User.UserName' --output text)
# if [ $? -ne 0 ]; then
#   echo "Failed to retrieve IAM User." 1>&2
#   exit 1
# fi

# Set the directory where your Terraform configuration files are located
TERRAFORM_BACKEND_DIR="terraform_backend"

# Navigate to the Terraform Backend directory
cd $TERRAFORM_BACKEND_DIR

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

if [ $? -eq 0 ]; then
    echo "Terraform initialized successfully."
else
    echo "Failed to initialize Terraform." 1>&2
    exit 1
fi

# Apply Terraform configuration
echo "Applying Terraform configuration for the dev environment..."
terraform apply -var="aws_region=$AWS_REGION" \
                -auto-approve

if [ $? -eq 0 ]; then
    echo "Terraform configuration applied successfully."
else
    echo "Failed to apply Terraform configuration." 1>&2
    exit 1
fi

# Retrieve the output of the S3 bucket name
BUCKET_NAME=$(terraform output -raw terraform_state_bucket_name)
# Retrieve the output of the Dynamo table name
TABLE_NAME=$(terraform output -raw terraform_state_locktable_name)
# Retrieve the role arn
# ROLE_ARN=$(terraform output -raw terraform_backend_role_arn)


# Check if the outputs and account info were successfully retrieved
if [ -n "$BUCKET_NAME" ] && [ -n "$TABLE_NAME" ] && [ -n "$AWS_REGION" ]; then
    BACKEND_CONFIG_API_PATH="../terraform/api/backend.tf"
    if [ ! -f "$BACKEND_CONFIG_API_PATH" ]; then
        echo "Creating backend.tf for api resources"
        touch "$BACKEND_CONFIG_API_PATH"
    fi

    BACKEND_CONFIG_ECR_PATH="../terraform/ecr/backend.tf"
    if [ ! -f "$BACKEND_CONFIG_ECR_PATH" ]; then
        echo "Creating backend.tf for ecr resources."
        touch "$BACKEND_CONFIG_ECR_PATH"
    fi
    
    # TODO: ideally we would write these values to AWS Secrets or something similar
cat <<EOF > "$BACKEND_CONFIG_API_PATH"
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }
    }
    backend "s3" {
        bucket         = "$BUCKET_NAME"
        key            = "dev/state/api/terraform.tfstate"
        region         = "$AWS_REGION"
        dynamodb_table = "$TABLE_NAME"
        encrypt        = true
    }
}
EOF

cat <<EOF > "$BACKEND_CONFIG_ECR_PATH"
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }
    }
    backend "s3" {
        bucket         = "$BUCKET_NAME"
        key            = "dev/state/ecr/terraform.tfstate"
        region         = "$AWS_REGION"
        dynamodb_table = "$TABLE_NAME"
        encrypt        = true
    }
}
EOF

else
    echo "Failed to retrieve necessary configuration." 1>&2
    exit 1
fi

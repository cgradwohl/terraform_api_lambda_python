provider "aws" {
  region = var.aws_region
}

####
# IAM
####
# custom policies
resource "aws_iam_policy" "sensor_data_bucket_read_only_policy" {
  name        = "sensor_data_bucket_read_only_policy"
  description = "S3 read-only access to sensor data bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.sensor_data_bucket.arn}",
          "${aws_s3_bucket.sensor_data_bucket.arn}/*"
        ]
      }
    ]
  })
}
resource "aws_iam_policy" "sensor_data_bucket_write_only_policy" {
  name        = "sensor_data_bucket_write_only_policy"
  description = "S3 write-only access to sensor data bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.sensor_data_bucket.arn}/*"
      }
    ]
  })
}
# authorizer role
resource "aws_iam_role" "authorizer_role" {
  name = "authorizer_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "authorizer_ecr_read" {
  role       = aws_iam_role.authorizer_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "authorizer_lambda_basic_execution" {
  role       = aws_iam_role.authorizer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "authorizer_ssm_read_only" {
  role       = aws_iam_role.authorizer_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}
# get_handler role
resource "aws_iam_role" "get_handler_role" {
  name = "get_handler_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "get_handler_ecr_read" {
  role       = aws_iam_role.get_handler_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "get_handler_lambda_basic_execution" {
  role       = aws_iam_role.get_handler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "get_handler_s3_read" {
  role       = aws_iam_role.get_handler_role.name
  policy_arn = aws_iam_policy.sensor_data_bucket_read_only_policy.arn
}
# ingest_handler role
resource "aws_iam_role" "ingest_handler_role" {
  name = "ingest_handler_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ingest_handler_ecr_read" {
  role       = aws_iam_role.ingest_handler_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "ingest_handler_lambda_basic_execution" {
  role       = aws_iam_role.ingest_handler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "ingest_handler_s3_write" {
  role       = aws_iam_role.ingest_handler_role.name
  policy_arn = aws_iam_policy.sensor_data_bucket_write_only_policy.arn
}
resource "aws_iam_role_policy_attachment" "ingest_handler_s3_read" {
  role       = aws_iam_role.ingest_handler_role.name
  policy_arn = aws_iam_policy.sensor_data_bucket_read_only_policy.arn
}
# lambda api gateway permissions
resource "aws_lambda_permission" "api_gateway_permission_get_handler" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.sensor_rest_api.execution_arn}/${var.stage}/GET/v1/{sensor_type}/{city}/{location}"
}
resource "aws_lambda_permission" "api_gateway_permission_ingest_handler" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.sensor_rest_api.execution_arn}/${var.stage}/POST/v1/{sensor_type}/{city}/{location}"
}
resource "aws_lambda_permission" "authorizer_permission" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.sensor_rest_api.execution_arn}/*/*"
}

####
# API Gateway
####
resource "aws_api_gateway_rest_api" "sensor_rest_api" {
  name = "sensor_rest_api"
}
resource "aws_api_gateway_authorizer" "sensor_rest_api_authorizer" {
  name                             = "sensor_rest_api_authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.sensor_rest_api.id
  authorizer_uri                   = aws_lambda_function.authorizer.invoke_arn
  type                             = "TOKEN"
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 600 # cache policy for 10 minutes to reduce ssm reads
}
# path definitions
resource "aws_api_gateway_resource" "sensor_rest_api_resource_v1" {
  rest_api_id = aws_api_gateway_rest_api.sensor_rest_api.id
  parent_id   = aws_api_gateway_rest_api.sensor_rest_api.root_resource_id
  path_part   = "v1"
}
resource "aws_api_gateway_resource" "sensor_type" {
  rest_api_id = aws_api_gateway_rest_api.sensor_rest_api.id
  parent_id   = aws_api_gateway_resource.sensor_rest_api_resource_v1.id
  path_part   = "{sensor_type}"
}
resource "aws_api_gateway_resource" "city" {
  rest_api_id = aws_api_gateway_rest_api.sensor_rest_api.id
  parent_id   = aws_api_gateway_resource.sensor_type.id
  path_part   = "{city}"
}
resource "aws_api_gateway_resource" "location" {
  rest_api_id = aws_api_gateway_rest_api.sensor_rest_api.id
  parent_id   = aws_api_gateway_resource.city.id
  path_part   = "{location}"
}
resource "aws_api_gateway_method" "api_method_post" {
  rest_api_id   = aws_api_gateway_rest_api.sensor_rest_api.id
  resource_id   = aws_api_gateway_resource.location.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.sensor_rest_api_authorizer.id
}
resource "aws_api_gateway_method" "api_method_get" {
  rest_api_id   = aws_api_gateway_rest_api.sensor_rest_api.id
  resource_id   = aws_api_gateway_resource.location.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.sensor_rest_api_authorizer.id
}
resource "aws_api_gateway_integration" "lambda_integration_post" {
  rest_api_id             = aws_api_gateway_rest_api.sensor_rest_api.id
  resource_id             = aws_api_gateway_resource.location.id
  http_method             = aws_api_gateway_method.api_method_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ingest_handler.invoke_arn
}
resource "aws_api_gateway_integration" "lambda_integration_get" {
  rest_api_id             = aws_api_gateway_rest_api.sensor_rest_api.id
  resource_id             = aws_api_gateway_resource.location.id
  http_method             = aws_api_gateway_method.api_method_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_handler.invoke_arn
}
resource "aws_api_gateway_deployment" "sensor_rest_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration_post,
    aws_api_gateway_integration.lambda_integration_get
  ]
  rest_api_id = aws_api_gateway_rest_api.sensor_rest_api.id
  stage_name  = var.stage
}

####
# Lambda
####
resource "aws_lambda_function" "authorizer" {
  function_name = "authorizer"
  architectures = ["arm64"]
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:authorizer_${var.image_tag}"
  role          = aws_iam_role.authorizer_role.arn
  timeout       = 15
  environment {
    variables = {
      API_KEY_PARAM_NAME = aws_ssm_parameter.api_key.name
    }
  }
}
resource "aws_lambda_function" "get_handler" {
  function_name = "get_handler"
  architectures = ["arm64"]
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:get_handler_${var.image_tag}"
  role          = aws_iam_role.get_handler_role.arn
  timeout       = 15
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.sensor_data_bucket.bucket
    }
  }
}
resource "aws_lambda_function" "ingest_handler" {
  function_name = "ingest_handler"
  architectures = ["arm64"]
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:ingest_handler_${var.image_tag}"
  role          = aws_iam_role.ingest_handler_role.arn
  timeout       = 15
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.sensor_data_bucket.bucket
    }
  }
}

####
# S3 Data Store
####
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}
resource "aws_s3_bucket" "sensor_data_bucket" {
  bucket = "sensor-data-bucket-${random_string.suffix.result}"
}
resource "aws_s3_object" "config_file" {
  bucket = aws_s3_bucket.sensor_data_bucket.bucket
  key    = "config.yml"
  source = "../../config.yml"
  etag   = filemd5("../../config.yml")
}

####
# Cloudwatch
####
resource "aws_cloudwatch_log_group" "authorizer_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.authorizer.function_name}"
  retention_in_days = 14
}
resource "aws_cloudwatch_log_group" "get_handler_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.get_handler.function_name}"
  retention_in_days = 14
}
resource "aws_cloudwatch_log_group" "ingest_handler_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.ingest_handler.function_name}"
  retention_in_days = 14
}

#####
# SSM
#####
resource "aws_ssm_parameter" "api_key" {
  name        = "API_KEY"
  description = "API Key for accessing the custom Lambda authorizer"
  type        = "SecureString"
  value       = "super-secret-key"
}


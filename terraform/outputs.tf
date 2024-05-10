output "ecr_repository_name" {
  value = aws_ecr_repository.sensor_rest_api_ecr_repo.name
}

output "invoke_url" {
  value = aws_api_gateway_deployment.sensor_rest_api_deployment.invoke_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.sensor_rest_api_ecr_repo.name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.sensor_rest_api_ecr_repo.repository_url
}

resource "aws_ecr_repository" "lambda_repository" {
  name = var.ecr_repo_name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "Lambda Shared Repo"
    Environment = "dev"
  }
}

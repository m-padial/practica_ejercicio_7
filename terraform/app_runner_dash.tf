# --- IAM Role para App Runner Dash ---
resource "aws_iam_role" "apprunner_dash_role" {
  name = "AppRunnerDashRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = [
            "build.apprunner.amazonaws.com",
            "tasks.apprunner.amazonaws.com"
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# --- Adjuntar política oficial de acceso a ECR ---
resource "aws_iam_role_policy_attachment" "apprunner_dash_ecr_policy" {
  role       = aws_iam_role.apprunner_dash_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# --- Servicio App Runner para la app Dash ---
resource "aws_apprunner_service" "dash_app" {
  service_name = "dash-volatilidad-app"

  depends_on = [
    aws_apprunner_service.api_backend,                    # Asegura que la API esté desplegada
    null_resource.run_pipeline_api,                       # Asegura que se hayan cargado los datos
    aws_iam_role.apprunner_dash_role,                     # Espera a que el rol esté creado
    aws_iam_role_policy_attachment.apprunner_dash_ecr_policy # Espera a que la política esté adjunta
  ]

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_dash_role.arn
    }

    image_repository {
      image_configuration {
        port = "8050"
        runtime_environment_variables = {
          API_URL = "https://${aws_apprunner_service.api_backend.service_url}"
        }
      }

      image_identifier      = "${aws_ecr_repository.lambda_repository.repository_url}:${var.image_tag_dash}"
      image_repository_type = "ECR"
    }

    auto_deployments_enabled = false
  }

  instance_configuration {
    cpu               = "1024"
    memory            = "2048"
    instance_role_arn = aws_iam_role.apprunner_dash_role.arn
  }

  tags = {
    Name        = "Dash Skew Volatilidad"
    Environment = "dev"
  }
}

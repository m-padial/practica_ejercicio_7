# --- Obtener ID de cuenta AWS
data "aws_caller_identity" "current" {}

# --- Rol IAM para App Runner con acceso a ECR y DynamoDB
resource "aws_iam_role" "apprunner_ecr_role" {
  name = "AppRunnerAutoCreatedRole"

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

# --- Adjuntar política oficial de ECR
resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy" {
  role       = aws_iam_role.apprunner_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# --- Política personalizada para DynamoDB
resource "aws_iam_role_policy" "apprunner_dynamodb_policy" {
  name = "AppRunnerDynamoDBAccess"
  role = aws_iam_role.apprunner_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:DescribeTable"
        ],
        Resource = "arn:aws:dynamodb:eu-west-1:${data.aws_caller_identity.current.account_id}:table/OpcionesFuturosMiniIBEX"
      }
    ]
  })
}

# --- Ejecutar la Step Function y ESPERAR hasta que termine con éxito
resource "null_resource" "run_pipeline" {
  depends_on = [aws_sfn_state_machine.pipeline_scraper_volatilidad]

  provisioner "local-exec" {
    command = <<EOT
      EXECUTION_ARN=$(aws stepfunctions start-execution \
        --state-machine-arn ${aws_sfn_state_machine.pipeline_scraper_volatilidad.arn} \
        --region eu-west-1 \
        --output text --query executionArn)

      echo "Step Function Execution ARN: $EXECUTION_ARN"

      while true; do
        STATUS=$(aws stepfunctions describe-execution \
          --execution-arn "$EXECUTION_ARN" \
          --region eu-west-1 \
          --query status --output text)

        echo "Estado actual: $STATUS"

        if [ "$STATUS" = "SUCCEEDED" ]; then
          echo "✅ Step Function completada correctamente."
          break
        elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "TIMED_OUT" ] || [ "$STATUS" = "ABORTED" ]; then
          echo "❌ Error: Step Function terminó con estado $STATUS"
          exit 1
        else
          sleep 5
        fi
      done
    EOT
  }
}



# --- Servicio App Runner
resource "aws_apprunner_service" "dash_app" {
  service_name = "volatilidad-dash-app"

  depends_on = [
    null_resource.run_pipeline,
    aws_iam_role.apprunner_ecr_role,
    aws_iam_role_policy.apprunner_dynamodb_policy
  ]

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_role.arn
    }

    image_repository {
      image_configuration {
        port = "8050"
      }
      image_identifier      = "${aws_ecr_repository.lambda_repository.repository_url}:dash"
      image_repository_type = "ECR"
    }

    auto_deployments_enabled = false
  }

  instance_configuration {
    cpu               = "1024"
    memory            = "2048"
    instance_role_arn = aws_iam_role.apprunner_ecr_role.arn
  }

  tags = {
    Name        = "Dash Volatilidad App"
    Environment = "dev"
  }
}

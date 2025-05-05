# IAM role para Step Function
resource "aws_iam_role" "step_function_role" {
  name = "step_function_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

# Permisos para que Step Function invoque ambas Lambdas
resource "aws_iam_role_policy" "step_function_policy" {
  name = "step_function_lambda_permissions"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = [
          aws_lambda_function.scraping_lambda.arn,
          aws_lambda_function.lambda_volatilidad.arn
        ]
      }
    ]
  })
}

# Step Function: Scraping → Volatilidad
resource "aws_sfn_state_machine" "pipeline_scraper_volatilidad" {
  name     = "pipeline_scraper_volatilidad"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "Pipeline: Scraper → Volatilidad",
    StartAt = "Scrapear datos",
    States = {
      "Scrapear datos" = {
        Type     = "Task",
        Resource = aws_lambda_function.scraping_lambda.arn,
        Next     = "Calcular volatilidad",
        Retry = [{
          ErrorEquals     = ["States.ALL"],
          IntervalSeconds = 2,
          MaxAttempts     = 2,
          BackoffRate     = 2.0
        }]
      },
      "Calcular volatilidad" = {
        Type     = "Task",
        Resource = aws_lambda_function.lambda_volatilidad.arn,
        End      = true,
        Retry = [{
          ErrorEquals     = ["States.ALL"],
          IntervalSeconds = 2,
          MaxAttempts     = 2,
          BackoffRate     = 2.0
        }]
      }
    }
  })
}
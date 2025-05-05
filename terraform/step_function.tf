# --- Obtener ID de cuenta AWS (si no lo tienes ya en otro archivo) ---
# data "aws_caller_identity" "current" {}

# --- Rol IAM para Step Function ---
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

# --- Política gestionada: Permitir invocar Lambdas desde Step Function ---
resource "aws_iam_policy" "step_function_policy" {
  name = "step_function_lambda_permissions"

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

# --- Adjuntar la política al rol ---
resource "aws_iam_role_policy_attachment" "step_function_policy_attachment" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_policy.arn
}

# --- Step Function: Scraping → Calcular Volatilidad ---
resource "aws_sfn_state_machine" "pipeline_scraper_volatilidad" {
  name     = "pipeline_scraper_volatilidad"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "Pipeline: Scraper → Volatilidad",
    StartAt = "Scrapear datos",
    States = {
      "Scrapear datos" = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Parameters = {
          FunctionName = aws_lambda_function.scraping_lambda.arn
        },
        Next = "Calcular volatilidad",
        Retry = [{
          ErrorEquals     = ["States.ALL"],
          IntervalSeconds = 2,
          MaxAttempts     = 2,
          BackoffRate     = 2.0
        }]
      },
      "Calcular volatilidad" = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Parameters = {
          FunctionName = aws_lambda_function.lambda_volatilidad.arn
        },
        End = true,
        Retry = [{
          ErrorEquals     = ["States.ALL"],
          IntervalSeconds = 2,
          MaxAttempts     = 2,
          BackoffRate     = 2.0
        }]
      }
    }
  })

  depends_on = [aws_iam_role_policy_attachment.step_function_policy_attachment]
}

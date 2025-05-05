# Regla de CloudWatch Events para ejecutar la Step Function cada 3 minutos
resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "daily_step_function_trigger"
  description         = "Dispara la Step Function cada 3 minutos"
  schedule_expression = "cron(0/10 * * * ? *)"
}

# Nuevo rol IAM que permite a EventBridge ejecutar la Step Function
resource "aws_iam_role" "eventbridge_step_role" {
  name = "eventbridge_invoke_step_function_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Política para permitir la ejecución de la Step Function
resource "aws_iam_role_policy" "eventbridge_step_policy" {
  name = "eventbridge_start_execution_policy"
  role = aws_iam_role.eventbridge_step_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "states:StartExecution",
      Resource = aws_sfn_state_machine.pipeline_scraper_volatilidad.arn
    }]
  })
}

# Target: conecta la regla al estado Step Function
resource "aws_cloudwatch_event_target" "start_step_function" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "StepFunctionTarget"
  arn       = aws_sfn_state_machine.pipeline_scraper_volatilidad.arn
  role_arn  = aws_iam_role.eventbridge_step_role.arn
}

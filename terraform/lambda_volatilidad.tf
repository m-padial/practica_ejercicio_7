resource "aws_lambda_function" "lambda_volatilidad" {
  function_name = "calcular_volatilidad_lambda"
  role          = aws_iam_role.lambda_exec_role.arn

  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repository.repository_url}:${var.image_tag_vol}"
  timeout       = 120
  memory_size   = 1536

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attach
  ]

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.scraping_data.name
    }
  }
}
resource "aws_lambda_permission" "step_volatilidad" {
  statement_id  = "AllowStepFunctionInvokeVolatilidad"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_volatilidad.function_name
  principal     = "states.amazonaws.com"
}

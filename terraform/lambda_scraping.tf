resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_scraping_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_scraping_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:Scan"
        ],
        Resource = aws_dynamodb_table.scraping_data.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_ecr_read_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_lambda_function" "scraping_lambda" {
  function_name = "scraping_opciones_futuros"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repository.repository_url}:${var.image_tag_scraper}"
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = 120
  memory_size   = 1536

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attach,
    aws_iam_role_policy_attachment.lambda_ecr_read_access
  ]

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.scraping_data.name
    }
  }
}


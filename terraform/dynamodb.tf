resource "aws_dynamodb_table" "scraping_data" {
  name           = "OpcionesFuturosMiniIBEX"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "fecha"
  range_key      = "tipo_id"

  attribute {
    name = "fecha"
    type = "S"
  }

  attribute {
    name = "tipo_id"
    type = "S"
  }

  tags = {
    Name        = "ScrapingDataTable"
    Environment = "dev"
  }
}

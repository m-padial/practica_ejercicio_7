variable "image_tag_scraper" {
  description = "Tag para la imagen Docker del scraper"
  type        = string
  default     = "scraper"
}

variable "image_tag_vol" {
  description = "Tag para la imagen Docker de volatilidad"
  type        = string
  default     = "volatilidad"
}

variable "image_tag_dash" {
  description = "Tag para la imagen Docker de la app Dash"
  type        = string
  default     = "dash"
}

variable "image_tag_api" {
  description = "Tag para la imagen Docker del backend FastAPI"
  type        = string
  default     = "api"
}

variable "ecr_repo_name" {
  description = "Nombre del repositorio ECR compartido para todas las funciones e imágenes"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
  default     = "eu-west-1"
}

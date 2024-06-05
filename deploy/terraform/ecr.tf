data "aws_ecr_image" "djangoweather_image" {
  repository_name = "django-weatherapp"
  most_recent     = true
}

data "aws_ecr_image" "nginx_image" {
  repository_name = "django-weatherapp-proxy"
  most_recent     = true
}

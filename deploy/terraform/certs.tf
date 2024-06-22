# request for an SSL certificate for our domain
resource "aws_acm_certificate" "weatherapp_certificate_request" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name : aws_route53_zone.weatherapp_zone.name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# resource which represents a successful validation of our SSL cert
# Used to insert DNS validation records into Route53 hosted zone
# and wait for successful validation
resource "aws_acm_certificate_validation" "weatherapp_certificate_validation" {
  certificate_arn         = aws_acm_certificate.weatherapp_certificate_request.arn
  validation_record_fqdns = [for record in aws_route53_record.weatherapp_validation_record : record.fqdn]
}
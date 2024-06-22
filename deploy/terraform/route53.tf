variable "domain_name" {
  default     = "robertscorner.click"
  type        = string
  description = "Domain name"
}

resource "aws_route53_zone" "weatherapp_zone" {
  name = var.domain_name
}

# Domain registered on Route53, with name servers set to the hosted zone's NS servers
resource "aws_route53domains_registered_domain" "domain" {
  domain_name = var.domain_name

  dynamic "name_server" {
    for_each = toset(aws_route53_zone.weatherapp_zone.name_servers)
    content {
      name = name_server.value
    }
  }
}

# Route53 alias records to point the domain to the load balancer
resource "aws_route53_record" "weatherapp_lb_record" {
  zone_id = aws_route53_zone.weatherapp_zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.weatherapp_lb.dns_name
    zone_id                = aws_lb.weatherapp_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "weatherapp_www_alias_record" {
  zone_id = aws_route53_zone.weatherapp_zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.weatherapp_lb.dns_name
    zone_id                = aws_lb.weatherapp_lb.zone_id
    evaluate_target_health = true
  }
}

# DNS validation record for SSL certificate
resource "aws_route53_record" "weatherapp_validation_record" {
  zone_id = aws_route53_zone.weatherapp_zone.zone_id
  for_each = {
    for dvo in aws_acm_certificate.weatherapp_certificate_request.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  allow_overwrite = true
  ttl             = 600
}

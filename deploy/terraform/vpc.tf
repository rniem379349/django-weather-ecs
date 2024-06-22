resource "aws_vpc" "weatherapp_vpc" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_hostnames = true
  tags = {
    name = "weatherapp_vpc"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.weatherapp_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.weatherapp_vpc.cidr_block, 8, 1)
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.weatherapp_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.weatherapp_vpc.cidr_block, 8, 2)
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.weatherapp_vpc.id
  tags = {
    Name = "internet_gateway"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.weatherapp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  route {
    cidr_block = aws_vpc.weatherapp_vpc.cidr_block
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "subnet_route" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet2_route" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "weatherapp_lb_sg" {
  name   = "weatherapp_lb_sg"
  vpc_id = aws_vpc.weatherapp_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "weatherapp_lb" {
  name               = "weatherapp-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.weatherapp_lb_sg.id]
  subnets            = [aws_subnet.subnet.id, aws_subnet.subnet2.id]

  tags = {
    Name = "weatherapp-lb"
  }
}

# Redirect http traffic to alb to https
resource "aws_lb_listener" "weatherapp_lb_listener" {
  load_balancer_arn = aws_lb.weatherapp_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "weatherapp_lb_https_listener" {
  load_balancer_arn = aws_lb.weatherapp_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.weatherapp_certificate_request.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.weatherapp_tg.arn
  }
}

resource "aws_lb_target_group" "weatherapp_tg" {
  name        = "weatherapp-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.weatherapp_vpc.id

  health_check {
    path = "/health"
  }
}

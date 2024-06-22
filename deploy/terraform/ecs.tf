resource "aws_ecs_cluster" "weatherapp_cluster" {
  name = "weatherapp_cluster"
}

resource "aws_ecs_cluster_capacity_providers" "ecs_capacity_provider" {
  cluster_name = aws_ecs_cluster.weatherapp_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# secrets manager secrets for app
data "aws_secretsmanager_secret_version" "weatherapp_secrets" {
  secret_id = "weatherapp_secrets"
}

locals {
  weatherapp_secrets = jsondecode(data.aws_secretsmanager_secret_version.weatherapp_secrets.secret_string)
}

resource "aws_ecs_task_definition" "weatherapp_task" {
  family             = "weatherapp_task"
  network_mode       = "awsvpc"
  execution_role_arn = "arn:aws:iam::387352317739:role/ecsTaskExecutionRole"
  task_role_arn      = "arn:aws:iam::387352317739:role/ecsTaskExecutionRole"
  cpu                = 512
  memory             = 2048
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name  = "django-weatherapp"
      image = data.aws_ecr_image.djangoweather_image.image_uri
      cpu   = 256
      portMappings = [
        {
          name          = "weatherapp-8080-tcp"
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
          appProtocol   = "http"
        },
      ]
      essential = true
      environment = [
        {
          name  = "AWS_ACCESS_KEY_ID"
          value = local.weatherapp_secrets.AWS_ACCESS_KEY_ID
        },
        {
          name  = "PROJECT_MODE"
          value = local.weatherapp_secrets.PROJECT_MODE
        },
        {
          name  = "AWS_S3_REGION_NAME",
          value = local.weatherapp_secrets.AWS_S3_REGION_NAME
        },
        {
          name  = "AWS_SECRET_ACCESS_KEY",
          value = local.weatherapp_secrets.AWS_SECRET_ACCESS_KEY
        },
        {
          name  = "DJANGO_SECRET_KEY",
          value = local.weatherapp_secrets.DJANGO_SECRET_KEY
        },
        {
          name  = "ALLOWED_HOSTS",
          value = "${aws_lb.weatherapp_lb.dns_name},${var.domain_name}"
        },
        {
          name  = "AWS_STORAGE_BUCKET_NAME",
          value = local.weatherapp_secrets.AWS_STORAGE_BUCKET_NAME
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_weatherapp_task.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name  = "django-weatherapp-proxy"
      image = data.aws_ecr_image.nginx_image.image_uri
      cpu   = 256
      portMappings = [
        {
          name          = "nginx-8000"
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
          appProtocol   = "http"
        },
      ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_weatherapp_task.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_security_group" "weatherapp_sg" {
  name   = "weatherapp_sg"
  vpc_id = aws_vpc.weatherapp_vpc.id

  ingress {
    from_port   = 8000
    to_port     = 8000
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

resource "aws_ecs_service" "weatherapp_service" {
  name                               = "weatherapp_service"
  cluster                            = aws_ecs_cluster.weatherapp_cluster.id
  task_definition                    = aws_ecs_task_definition.weatherapp_task.arn
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = [aws_subnet.subnet.id, aws_subnet.subnet2.id]
    security_groups  = [aws_security_group.weatherapp_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.weatherapp_tg.arn
    container_name   = "django-weatherapp-proxy"
    container_port   = 8000
  }
}

# hl-infra/main.tf

provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "hl-vpc"
  cidr   = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.12.0"

  identifier = "hl-deals-db-dev"

  engine               = "sqlserver-ex"
  family               = "sqlserver-ex-15.0"
  major_engine_version = "15.00"
  license_model        = "license-included"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  port                  = 1433

  username = var.db_username
  password = ***REDACTED***
  # db_name               = var.db_name   # si diera error, omítelo para SQL Server

  # ⚠️ Estas subredes son las PRIVADAS de TU VPC
  subnet_ids             = module.network.private_subnets
  create_db_subnet_group = true

  # ⚠️ Este SG es el nativo que acabamos de definir (en la misma VPC)
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true

  depends_on = [null_resource.depends_network]
}


# module "db_sg" {
#   source  = "terraform-aws-modules/security-group/aws"
#   name    = "hl-db-sg"
#   vpc_id  = module.network.vpc_id

#   ingress_with_cidr_blocks = [{
#     from_port   = 1433
#     to_port     = 1433
#     protocol    = "tcp"
#     cidr_blocks = "0.0.0.0/0" # (adjust later to backend ECS IP range or bastion only)
#   }]

#   egress_with_cidr_blocks = [{
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = "0.0.0.0/0"
#   }]
# }

resource "aws_security_group" "rds_sg" {
  name        = "hl-rds-sg"
  description = "Allow SQL Server from VPC only"
  vpc_id      = module.network.vpc_id # <- amarrado a TU VPC

  # ingress {
  #   from_port   = 1433
  #   to_port     = 1433
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]       # tu CIDR de la VPC (ajústalo si cambiaste)
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "hl-rds-sg" }
}

# (opcional, solo para asegurar orden)
resource "null_resource" "depends_network" {
  depends_on = [module.network]
}

resource "aws_security_group_rule" "rds_allow_from_ecs" {
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id # destino: el SG de la DB
  source_security_group_id = aws_security_group.ecs_sg.id # origen: el SG del ECS
}

module "s3_frontend" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"

  bucket = "hl-deals-web-${var.environment}"

  # IMPORTANT: NO ACLs
  acl                      = null
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  # Permite políticas públicas (solo si quieres sitio público)
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false

  website = {
    index_document = "index.html"
    error_document = "index.html"
  }

  # Adjuntar una policy pública de solo lectura a objetos
  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowPublicRead",
      Effect    = "Allow",
      Principal = "*",
      Action    = ["s3:GetObject"],
      Resource  = ["arn:aws:s3:::hl-deals-web-${var.environment}/*"]
    }]
  })

  tags = {
    Project = "hl-showcase"
  }
}



############################################
# ECS + ECR + Task Definition
############################################


# module "ecr" {
#   source = "terraform-aws-modules/ecr/aws"
#   repository_name = "hl-api"
#   create_repository = true
#   repository_read_write_access_arns = []
# }

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.0.1"

  repository_name         = "hl-api"
  create_lifecycle_policy = true

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_security_group" "ecs_sg" {
  name        = "hl-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.network.vpc_id

  # Salida a internet (NAT) para que el task pueda llegar a RDS/servicios externos
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "hl-ecs-sg" }
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.3.0"

  cluster_name                = "hl-ecs-cluster"
  create_cloudwatch_log_group = true

  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 1
      base   = 0
    }
  }
}


# module "ecs_task_exec_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
#   version = "5.34.0"

#   create_role           = true
#   role_name             = "hl-task-exec-role"
#   trusted_role_services = ["ecs-tasks.amazonaws.com"]

#   custom_role_policy_arns = [
#     "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
#   ]
# }



resource "aws_ecs_task_definition" "hl_api" {
  family                   = "hl-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  # execution_role_arn       = module.ecs_task_exec_role.iam_role_arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name  = "hl-api"
      image = "${module.ecr.repository_url}:latest"
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "ASPNETCORE_ENVIRONMENT", value = "Production" },
        { name = "ASPNETCORE_URLS", value = "http://+:8080" }, # 👈 clave
        { name = "ConnectionStrings__DefaultConnection", value = var.db_connection_string },
        { name = "Jwt__Key", value = var.jwt_key },
        { name = "Jwt__Issuer", value = var.jwt_issuer },
        { name = "Jwt__Audience", value = var.jwt_audience }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/hl-api",
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "hl_api" {
  name            = "hl-api-service"
  cluster         = module.ecs_cluster.cluster_id
  task_definition = aws_ecs_task_definition.hl_api.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  health_check_grace_period_seconds = 60



  network_configuration {
    subnets          = module.network.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_sg.id] # <-- aquí el nuevo SG de ECS
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api_tg.arn
    container_name   = "hl-api" # debe coincidir con containerDefinitions[].name
    container_port   = 8080
  }

  depends_on = [aws_ecs_task_definition.hl_api, aws_lb_listener.http]
}



# LOGS

resource "aws_cloudwatch_log_group" "hl_api" {
  name              = "/ecs/hl-api"
  retention_in_days = 7
}



# Execution role para tareas ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "hl-task-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect="Allow", Principal={ Service="ecs-tasks.amazonaws.com" }, Action="sts:AssumeRole"}]
  })
}

# Política gestionada estándar para execution role
resource "aws_iam_role_policy_attachment" "ecs_task_exec_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# ALB SG: permite HTTP desde internet
resource "aws_security_group" "alb_sg" {
  name        = "hl-alb-sg"
  description = "ALB inbound 80 from internet"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "hl-alb-sg" }
}

# Permite al ALB hablar con las tareas ECS en el puerto 80
resource "aws_security_group_rule" "ecs_allow_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_sg.id # destino = SG de ECS
  source_security_group_id = aws_security_group.alb_sg.id # origen = SG del ALB
}





resource "aws_lb" "api_alb" {
  name               = "hl-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.network.public_subnets
}
resource "random_id" "tg" { byte_length = 2 } # sufijo corto (4 hex)

resource "aws_lb_target_group" "api_tg" {
  name        = "hl-api-${random_id.tg.hex}"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip" # Fargate => IP
  vpc_id      = module.network.vpc_id

  health_check {
    path                = "/healthz" # ver nota abajo
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = true # 👈 evita intentar borrar el TG viejo antes
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }
}


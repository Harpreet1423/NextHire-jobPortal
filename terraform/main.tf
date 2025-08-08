provider "aws" {
  region = var.aws_region
}

# --------- VPC Module ---------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "job-portal-vpc"
  cidr = var.vpc_cidr

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "shared"
  }
}

# --------- ECR Repo ---------
resource "aws_ecr_repository" "job_portal" {
  name = "job-portal"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "job-portal-ecr"
    Environment = "shared"
  }
}

# --------- IAM Role for ECS Task Execution ---------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "job-portal-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --------- STAGING ENVIRONMENT ---------

resource "aws_ecs_cluster" "staging" {
  name = "job-portal-staging-cluster"
  tags = { Environment = "staging" }
}

resource "aws_security_group" "staging_lb_sg" {
  name        = "staging-lb-sg"
  description = "Security group for Staging ALB"
  vpc_id      = module.vpc.vpc_id

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

  tags = { Environment = "staging" }
}

resource "aws_security_group" "staging_ecs_sg" {
  name        = "staging-ecs-sg"
  description = "Security group for Staging ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.staging_lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Environment = "staging" }
}

resource "aws_lb" "staging_alb" {
  name               = "job-portal-staging-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.staging_lb_sg.id]
  subnets            = module.vpc.public_subnets

  tags = { Environment = "staging" }
}

resource "aws_lb_target_group" "staging_tg" {
  name        = "job-portal-staging-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Environment = "staging" }
}

resource "aws_lb_listener" "staging_listener" {
  load_balancer_arn = aws_lb.staging_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.staging_tg.arn
  }

  tags = { Environment = "staging" }
}

resource "aws_ecs_task_definition" "staging_task" {
  family                   = "job-portal-staging-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_task_cpu_staging
  memory                   = var.ecs_task_memory_staging
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name         = "job-portal-staging-container"
      image        = "${aws_ecr_repository.job_portal.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 80, hostPort = 80, protocol = "tcp" }]
      environment  = [{ name = "NODE_ENV", value = "staging" }]
    }
  ])

  tags = { Environment = "staging" }
}

resource "aws_ecs_service" "staging_service" {
  name            = "job-portal-staging-service"
  cluster         = aws_ecs_cluster.staging.id
  task_definition = aws_ecs_task_definition.staging_task.arn
  launch_type     = "FARGATE"
  desired_count   = var.staging_desired_count

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.staging_ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.staging_tg.arn
    container_name   = "job-portal-staging-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.staging_listener]

  tags = { Environment = "staging" }
}

# --------- PRODUCTION ENVIRONMENT ---------

resource "aws_ecs_cluster" "production" {
  name = "job-portal-production-cluster"
  tags = { Environment = "production" }
}

resource "aws_security_group" "production_lb_sg" {
  name        = "production-lb-sg"
  description = "Security group for Production ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Environment = "production" }
}

resource "aws_security_group" "production_ecs_sg" {
  name        = "production-ecs-sg"
  description = "Security group for Production ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.production_lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Environment = "production" }
}

resource "aws_lb" "production_alb" {
  name               = "job-portal-production-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.production_lb_sg.id]
  subnets            = module.vpc.public_subnets

  tags = { Environment = "production" }
}

resource "aws_lb_target_group" "production_tg" {
  name        = "job-portal-production-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }

  tags = { Environment = "production" }
}

resource "aws_lb_listener" "production_listener" {
  load_balancer_arn = aws_lb.production_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.production_tg.arn
  }

  tags = { Environment = "production" }
}

resource "aws_ecs_task_definition" "production_task" {
  family                   = "job-portal-production-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_task_cpu_prod
  memory                   = var.ecs_task_memory_prod
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name         = "job-portal-production-container"
      image        = "${aws_ecr_repository.job_portal.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 80, hostPort = 80, protocol = "tcp" }]
      environment  = [{ name = "NODE_ENV", value = "production" }]
    }
  ])

  tags = { Environment = "production" }
}

resource "aws_ecs_service" "production_service" {
  name            = "job-portal-production-service"
  cluster         = aws_ecs_cluster.production.id
  task_definition = aws_ecs_task_definition.production_task.arn
  launch_type     = "FARGATE"
  desired_count   = var.prod_desired_count

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.production_ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.production_tg.arn
    container_name   = "job-portal-production-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.production_listener]

  tags = { Environment = "production" }
}



# provider "aws" {
#   region = "us-east-1"
# }

# # ----------------------------
# # ECR REPO
# # ----------------------------
# resource "aws_ecr_repository" "job_portal" {
#   name = "job-portal"

#   image_scanning_configuration {
#     scan_on_push = true
#   }

#   tags = {
#     Name        = "job-portal-ecr"
#     Environment = "dev"
#   }
# }

# # ----------------------------
# # IAM ROLE FOR ECS TASK EXECUTION
# # ----------------------------
# data "aws_iam_role" "ecs_task_execution_role" {
#   name = "ecsTaskExecutionRole"
# }

# # ----------------------------
# # VPC MODULE
# # ----------------------------
# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "5.1.2"

#   name = "job-portal-vpc"
#   cidr = "10.0.0.0/16"

#   azs             = ["us-east-1a", "us-east-1b"]
#   public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
#   private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

#   enable_nat_gateway     = true
#   single_nat_gateway     = true
#   enable_dns_hostnames   = true
#   enable_dns_support     = true

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }

# # ----------------------------
# # ECS CLUSTER
# # ----------------------------
# resource "aws_ecs_cluster" "job_portal_cluster" {
#   name = "job-portal-cluster"
# }

# # ----------------------------
# # ECS TASK DEFINITION
# # ----------------------------
# resource "aws_ecs_task_definition" "job_portal_task" {
#   family                   = "job-portal-task"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = "256"
#   memory                   = "512"
#   execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

#   container_definitions = jsonencode([{
#     name         = "job-portal-container"
#     image        = "${aws_ecr_repository.job_portal.repository_url}:latest"
#     portMappings = [{
#       containerPort = 80
#       hostPort      = 80
#       protocol      = "tcp"
#     }]
#     essential = true
#   }])
# }

# # ----------------------------
# # SECURITY GROUP FOR ALB
# # ----------------------------
# resource "aws_security_group" "lb_sg" {
#   name        = "lb-sg"
#   description = "Security group for ALB"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "lb-sg"
#   }
# }

# # ----------------------------
# # SECURITY GROUP FOR ECS
# # ----------------------------
# resource "aws_security_group" "ecs_sg" {
#   name        = "ecs-tasks-sg"
#   description = "Security group for ECS tasks"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "ecs-sg"
#   }
# }

# # ----------------------------
# # APPLICATION LOAD BALANCER
# # ----------------------------
# resource "aws_lb" "job_portal_alb" {
#   name               = "job-portal-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.lb_sg.id]
#   subnets            = module.vpc.public_subnets
# }

# # ----------------------------
# # TARGET GROUP
# # ----------------------------
# resource "aws_lb_target_group" "job_portal_tg" {
#   name        = "job-portal-tg"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = module.vpc.vpc_id
#   target_type = "ip"

#   health_check {
#     path                = "/"
#     protocol            = "HTTP"
#     matcher             = "200-399"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 3
#     unhealthy_threshold = 2
#   }
# }

# # ----------------------------
# # ALB LISTENER
# # ----------------------------
# resource "aws_lb_listener" "http_listener" {
#   load_balancer_arn = aws_lb.job_portal_alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.job_portal_tg.arn
#   }
# }

# # ----------------------------
# # ECS SERVICE
# # ----------------------------
# resource "aws_ecs_service" "job_portal_service" {
#   name            = "job-portal-service"
#   cluster         = aws_ecs_cluster.job_portal_cluster.id
#   task_definition = aws_ecs_task_definition.job_portal_task.arn
#   launch_type     = "FARGATE"

#   network_configuration {
#     subnets          = module.vpc.public_subnets
#     security_groups  = [aws_security_group.ecs_sg.id]
#     assign_public_ip = true
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.job_portal_tg.arn
#     container_name   = "job-portal-container"
#     container_port   = 80
#   }

#   depends_on = [aws_lb_listener.http_listener]
# }










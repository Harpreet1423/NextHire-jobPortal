provider "aws" {
  region = "us-east-1"
}

# ----------------------------
# VPC MODULE
# ----------------------------
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "job-portal-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# ----------------------------
# ECS CLUSTER
# ----------------------------
resource "aws_ecs_cluster" "job_portal_cluster" {
  name = "job-portal-cluster"
}

# ----------------------------
# ECS TASK DEFINITION
# ----------------------------
resource "aws_ecs_task_definition" "job_portal_task" {
  family                   = "job-portal-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "job-portal-container"
      image     = "${var.ecr_repo}:${var.image_tag}"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  execution_role_arn = var.ecs_task_execution_role_arn
}

# ----------------------------
# SECURITY GROUP FOR ALB
# ----------------------------
resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Security group for ALB"
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

  tags = {
    Name = "lb-sg"
  }
}

# ----------------------------
# SECURITY GROUP FOR ECS
# ----------------------------
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-sg"
  }
}

# ----------------------------
# APPLICATION LOAD BALANCER
# ----------------------------
resource "aws_lb" "job_portal_alb" {
  name               = "job-portal-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = module.vpc.public_subnets
}

# ----------------------------
# TARGET GROUP
# ----------------------------
resource "aws_lb_target_group" "job_portal_tg" {
  name        = "job-portal-tg"
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
}

# ----------------------------
# ALB LISTENER
# ----------------------------
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.job_portal_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.job_portal_tg.arn
  }
}

# ----------------------------
# ECS SERVICE
# ----------------------------
resource "aws_ecs_service" "job_portal_service" {
  name            = "job-portal-service"
  cluster         = aws_ecs_cluster.job_portal_cluster.id
  task_definition = aws_ecs_task_definition.job_portal_task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.job_portal_tg.arn
    container_name   = "job-portal-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http_listener]
}




# provider "aws" {
#   region = var.aws_region
# }

# resource "aws_ecr_repository" "job_portal" {
#   name                 = "job-portal"
#   image_tag_mutability = "MUTABLE"
#   force_delete         = true  # ✅ Ensures ECR repo can be destroyed cleanly

#   image_scanning_configuration {
#     scan_on_push = true
#   }

#   lifecycle {
#     prevent_destroy = false    # ✅ Optional: false is safer when using force_delete
#     ignore_changes  = [tags]
#   }
# }

# resource "aws_ecs_cluster" "job_portal_cluster" {
#   name = "job-portal-cluster"
# }

# data "aws_iam_role" "ecs_task_execution_role" {
#   name = "ecsTaskExecutionRole"
# }

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "5.1.0"

#   name = "job-portal-vpc"
#   cidr = "10.0.0.0/16"

#   azs             = ["${var.aws_region}a", "${var.aws_region}b"]
#   public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
#   enable_dns_hostnames = true

#   tags = {
#     Terraform   = "true"
#     Environment = "staging"
#   }
# }

# resource "aws_security_group" "lb_sg" {
#   name        = "job-portal-alb-sg"
#   description = "Allow HTTP"
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
# }

# resource "aws_lb" "job_portal_alb" {
#   name               = "job-portal-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.lb_sg.id]
#   subnets            = module.vpc.public_subnets
# }

# resource "aws_lb_target_group" "job_portal_tg" {
#   name     = "job-portal-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = module.vpc.vpc_id

#   health_check {
#     path                = "/"
#     protocol            = "HTTP"
#     matcher             = "200-399"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#   }
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.job_portal_alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.job_portal_tg.arn
#   }
# }








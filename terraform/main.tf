provider "aws" {
  region = var.aws_region
}

# ─────────────────────────────────────────────────────────
# ECR Repository for Docker Images
# ─────────────────────────────────────────────────────────
resource "aws_ecr_repository" "job_portal" {
  name                 = "job-portal"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}

# ─────────────────────────────────────────────────────────
# ECS Cluster
# ─────────────────────────────────────────────────────────
resource "aws_ecs_cluster" "job_portal_cluster" {
  name = "job-portal-cluster"
}

# ─────────────────────────────────────────────────────────
# IAM Role for ECS Tasks (pre-created)
# ─────────────────────────────────────────────────────────
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

# ─────────────────────────────────────────────────────────
# VPC
# ─────────────────────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "job-portal-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "staging"
  }
}

# ─────────────────────────────────────────────────────────
# Security Group for ALB
# ─────────────────────────────────────────────────────────
resource "aws_security_group" "lb_sg" {
  name        = "job-portal-alb-sg"
  description = "Allow HTTP"
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
}

# ─────────────────────────────────────────────────────────
# Application Load Balancer (ALB)
# ─────────────────────────────────────────────────────────
resource "aws_lb" "job_portal_alb" {
  name               = "job-portal-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = module.vpc.public_subnets
}

# ─────────────────────────────────────────────────────────
# Target Group
# ─────────────────────────────────────────────────────────
resource "aws_lb_target_group" "job_portal_tg" {
  name        = "job-portal-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"  # <-- THIS FIXES THE ERROR

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


# ─────────────────────────────────────────────────────────
# ALB Listener
# ─────────────────────────────────────────────────────────
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.job_portal_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.job_portal_tg.arn
  }
}

# ─────────────────────────────────────────────────────────
# ECS Task Definition
# ─────────────────────────────────────────────────────────
resource "aws_ecs_task_definition" "job_portal_task" {
  family                   = "job-portal-task"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "job-portal-container"
      image     = "${aws_ecr_repository.job_portal.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# ─────────────────────────────────────────────────────────
# ECS Service
# ─────────────────────────────────────────────────────────
resource "aws_ecs_service" "job_portal_service" {
  name            = "job-portal-service"
  cluster         = aws_ecs_cluster.job_portal_cluster.id
  task_definition = aws_ecs_task_definition.job_portal_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.public_subnets
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.job_portal_tg.arn
    container_name   = "job-portal-container"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http_listener
  ]
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








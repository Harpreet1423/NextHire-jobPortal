provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "job_portal" {
  name                 = "job-portal"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "job_portal_cluster" {
  name = "job-portal-cluster"
}

# (Optional) IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "~> 1.0"
    }
  }
}



resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

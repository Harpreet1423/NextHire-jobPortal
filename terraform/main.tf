provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "job_portal" {
  name                 = "job-portal"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

# Example usage (if needed): you can reference the role as:
# data.aws_iam_role.ecs_task_execution_role.arn



# provider "aws" {
#   region = var.aws_region
# }

# resource "aws_ecr_repository" "job_portal" {
#   name                 = "job-portal"
#   image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }

#   lifecycle {
#     ignore_changes = [
#     image_scanning_configuration,
#     image_tag_mutability
#   ]
#   }
# }

# resource "aws_ecs_cluster" "job_portal_cluster" {
#   name = "job-portal-cluster"
# }

# resource "aws_iam_role" "ecs_task_execution_role" {
#   name = "ecsTaskExecutionRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action    = "sts:AssumeRole"
#       Effect    = "Allow"
#       Principal = {
#         Service = "ecs-tasks.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

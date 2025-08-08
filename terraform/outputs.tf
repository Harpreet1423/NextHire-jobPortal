output "ecr_repository_url" {
  description = "ECR Repository URL for job-portal"
  value       = aws_ecr_repository.job_portal.repository_url
}

# Staging Outputs
output "staging_cluster_arn" {
  description = "ARN of the ECS cluster for staging"
  value       = aws_ecs_cluster.staging.arn
}

output "staging_alb_dns" {
  description = "DNS name of the staging ALB"
  value       = aws_lb.staging_alb.dns_name
}

output "staging_target_group_arn" {
  description = "ARN of the staging ALB target group"
  value       = aws_lb_target_group.staging_tg.arn
}

output "staging_ecs_service_name" {
  description = "Name of the ECS service in staging"
  value       = aws_ecs_service.staging_service.name
}

# Production Outputs
output "production_cluster_arn" {
  description = "ARN of the ECS cluster for production"
  value       = aws_ecs_cluster.production.arn
}

output "production_alb_dns" {
  description = "DNS name of the production ALB"
  value       = aws_lb.production_alb.dns_name
}

output "production_target_group_arn" {
  description = "ARN of the production ALB target group"
  value       = aws_lb_target_group.production_tg.arn
}

output "production_ecs_service_name" {
  description = "Name of the ECS service in production"
  value       = aws_ecs_service.production_service.name
}



# output "ecr_repo_url" {
#   description = "ECR repository URL"
#   value       = aws_ecr_repository.job_portal.repository_url
# }

# output "ecs_cluster_name" {
#   description = "Name of the ECS cluster"
#   value       = aws_ecs_cluster.job_portal_cluster.name
# }

# output "ecs_task_execution_role_arn" {
#   description = "ECS Task Execution Role ARN"
#   value       = data.aws_iam_role.ecs_task_execution_role.arn
# }

# output "alb_dns_name" {
#   description = "Application Load Balancer DNS"
#   value       = aws_lb.job_portal_alb.dns_name
# }

# output "vpc_id" {
#   description = "VPC ID from the VPC module"
#   value       = module.vpc.vpc_id
# }

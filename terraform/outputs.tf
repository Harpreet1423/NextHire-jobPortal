output "ecr_repo_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.job_portal.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.job_portal_cluster.name
}

output "ecs_task_execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  value       = data.aws_iam_role.ecs_task_execution_role.arn
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS"
  value       = aws_lb.job_portal_alb.dns_name
}

output "vpc_id" {
  description = "VPC ID from the VPC module"
  value       = module.vpc.vpc_id
}

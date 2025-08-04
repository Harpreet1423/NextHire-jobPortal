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
  value       = aws_iam_role.ecs_task_execution_role.arn
}

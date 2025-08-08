variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to create a single NAT Gateway for all AZs"
  type        = bool
  default     = true
}

variable "ecs_task_cpu_staging" {
  description = "CPU units for staging ECS task"
  type        = string
  default     = "256"
}

variable "ecs_task_memory_staging" {
  description = "Memory (MB) for staging ECS task"
  type        = string
  default     = "512"
}

variable "staging_desired_count" {
  description = "Number of ECS tasks to run in staging"
  type        = number
  default     = 1
}

variable "ecs_task_cpu_prod" {
  description = "CPU units for production ECS task"
  type        = string
  default     = "512"
}

variable "ecs_task_memory_prod" {
  description = "Memory (MB) for production ECS task"
  type        = string
  default     = "1024"
}

variable "prod_desired_count" {
  description = "Number of ECS tasks to run in production"
  type        = number
  default     = 2
}


# variable "aws_region" {
#   description = "AWS region to deploy into"
#   type        = string
#   default     = "us-east-1"
# }

# variable "instance_type" {
#   description = "Instance type for ECS (if you use EC2 mode)"
#   type        = string
#   default     = "t3.micro"
# }

# variable "vpc_cidr" {
#   description = "CIDR block for the VPC"
#   type        = string
#   default     = "10.0.0.0/16"
# }

# variable "public_subnets" {
#   description = "List of public subnet CIDRs"
#   type        = list(string)
#   default     = ["10.0.1.0/24", "10.0.2.0/24"]
# }

# variable "private_subnets" {
#   description = "List of private subnet CIDRs"
#   type        = list(string)
#   default     = ["10.0.3.0/24", "10.0.4.0/24"]
# }


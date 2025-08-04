variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Instance type for ECS (if you use EC2 mode)"
  type        = string
  default     = "t3.micro"
}
# data "civo_snapshot" "mysql-vm" {
#     name = "mysql-vm"
# }
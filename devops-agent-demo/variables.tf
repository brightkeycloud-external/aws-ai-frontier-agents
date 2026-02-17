variable "env" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "project" {
  description = "Project name used in resource naming"
  type        = string
  default     = "devops-agent"
}

variable "aws_region" {
  description = "AWS region - must be us-east-1 for DevOps Agent"
  type        = string
  default     = "us-east-1"
}

variable "costcenter" {
  description = "Cost center code for tagging"
  type        = string
  default     = "demo"
}

variable "repo" {
  description = "GitHub repo name for tagging"
  type        = string
  default     = "ai-config"
}

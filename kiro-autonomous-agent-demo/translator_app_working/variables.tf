variable "env" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "project" {
  description = "Project name used in resource naming"
  type        = string
  default     = "kiro-agent"
}

variable "aws_region" {
  description = "AWS region for deployment"
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
  default     = "aws-ai-frontier-agents"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "project" {
  description = "Project name used in resource naming"
  type        = string
  default     = "security-agent"
}

variable "aws_region" {
  description = "AWS region - must be us-east-1 for Security Agent"
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

variable "hosted_zone_name" {
  description = "Route 53 hosted zone name (e.g., example.com). ACM cert must exist for this domain."
  type        = string
}

variable "domain_name" {
  description = "Subdomain for the API (e.g., securitydemo.example.com)"
  type        = string
}

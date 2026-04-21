terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }

  s3_us_east_1_regional_endpoint = "regional"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- Discover latest Claude Haiku model ---
data "aws_bedrock_foundation_models" "anthropic" {
  by_provider        = "Anthropic"
  by_output_modality = "TEXT"
}

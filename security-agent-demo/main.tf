terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

data "aws_region" "current" {}

data "aws_route53_zone" "demo" {
  name = var.hosted_zone_name
}

data "aws_acm_certificate" "demo" {
  domain      = var.hosted_zone_name
  statuses    = ["ISSUED"]
  most_recent = true
}

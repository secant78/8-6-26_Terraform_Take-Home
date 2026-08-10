terraform {
  required_version = ">= 1.15.0"

  backend "s3" {
    bucket       = "secant78-terraform-state-dev"
    key          = "aws/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Provider    = "AWS"
      ManagedBy   = "Terraform"
    }
  }
}
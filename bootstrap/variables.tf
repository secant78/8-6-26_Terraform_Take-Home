variable "aws_region" {
  description = "AWS region for bootstrap infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "github_repo" {
  description = "GitHub repository string (username/repo-name)"
  type        = string
  default     = "secant78/8-6-26_Terraform_Take-Home"
}
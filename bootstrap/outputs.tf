output "s3_bucket_name" {
  description = "S3 Bucket Name for Terraform State"
  value       = aws_s3_bucket.terraform_state.id
}

output "oidc_role_arn" {
  description = "IAM Role ARN for GitHub Actions OIDC"
  value       = aws_iam_role.github_oidc.arn
}
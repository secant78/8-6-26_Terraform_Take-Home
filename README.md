# Terraform Take-Home: AWS Web Infrastructure

Terraform configuration provisioning a VPC, public/private subnets, an SSL-terminating Application Load Balancer, and a private EC2 web server on AWS — built for the Cloud Infrastructure ENG take-home exercise.

## Repository Layout

```text
.
├── modules/aws/            # Reusable Terraform modules
│   ├── vpc/                 # VPC, subnets, route tables, IGW, NAT gateway
│   ├── security_group/      # ALB and EC2 security groups
│   ├── alb/                 # ALB, self-signed TLS cert, target group, listeners
│   └── ec2/                 # EC2 instance + Nginx user-data
├── environments/aws/dev/   # The actual deployable environment — start here
└── bootstrap/               # One-time setup: S3 state backend + GitHub Actions OIDC role
```

**The take-home deliverable lives in [`environments/aws/dev/`](environments/aws/dev/README.md)** — that directory's README has the full setup, assumptions, and verification instructions required by the exercise. This root README is a map to get you there.

## Quick Start

```bash
cd environments/aws/dev
terraform init
terraform plan
terraform apply
```

Terraform state is stored remotely in S3 (see `bootstrap/`), so no local state file is created. Full details, prerequisites, and verification steps: [environments/aws/dev/README.md](environments/aws/dev/README.md).

## What's Included

- **VPC** (`10.0.0.0/16`) with 2 public + 2 private subnets across 2 availability zones
- **Security groups**: ALB allows HTTP/HTTPS from anywhere; EC2 allows HTTP only from the ALB and SSH only from within the VPC
- **ALB** terminating SSL with a self-signed certificate, forwarding to the EC2 instance
- **EC2 instance** in a private subnet running Nginx, reachable only through the ALB
- **Outputs**: ALB DNS name and EC2 private IP

## Beyond the Spec

The exercise didn't require it, but this repo also includes:

- **`bootstrap/`** — a one-time-apply Terraform config that provisions the S3 state backend and a GitHub Actions OIDC IAM role, so CI never needs long-lived AWS credentials.
- **`.github/workflows/terraform.yml`** — a CI/CD pipeline that runs `fmt -check`, `plan`, and `apply` automatically via GitHub Actions using OIDC federation.

Neither is required to run the `environments/aws/dev` deployment locally — see the Quick Start above.

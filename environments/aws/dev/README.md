# AWS Dev Environment Infrastructure (Terraform)

This repository provisions an AWS infrastructure using modularized, production-grade Terraform configurations. The architecture includes a custom VPC with public and private subnets, an Application Load Balancer (ALB) terminating SSL via a self-signed certificate, and an EC2 web server running Nginx strictly inside a private subnet.

## Repository Architecture

```text
.
├── modules/
│   └── aws/                       # AWS-specific infrastructure modules
│       ├── vpc/                   # VPC, Subnets, Route Tables, Internet & NAT Gateways
│       ├── security_group/        # Inbound/Outbound security rules for ALB & EC2
│       ├── alb/                   # ALB, TLS self-signed cert, Target Group, Listeners
│       └── ec2/                   # EC2 instance & Nginx startup user-data script
└── environments/
    └── aws/
        └── dev/                   # AWS Development Environment Root
            ├── providers.tf       # Provider sources, versions, and region default tags
            ├── main.tf            # Module orchestration and inter-module wiring
            ├── variables.tf       # Environment input definitions
            ├── terraform.tfvars   # Concrete variable values
            ├── outputs.tf         # ALB DNS Name and EC2 Private IP outputs
            └── README.md          # Deployment & verification guide
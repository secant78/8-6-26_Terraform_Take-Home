# Modular Infrastructure Deployment (Dev Environment)

This repository contains modularized Terraform configurations to provision an AWS VPC infrastructure with an ALB terminating SSL, and an EC2 web server situated inside a private subnet.

## Folder Hierarchy
```text
.
├── modules/               # Reusable terraform modules
│   ├── vpc/               # VPC, Subnets, Route tables, Internet & NAT Gateways
│   ├── security_groups/   # Traffic rules for ALB & EC2
│   ├── alb/               # ALB, ACM self-signed cert, Target Group, Listeners
│   └── ec2/               # EC2 instance & Nginx user data startup script
└── environments/
    └── dev/               # Development environment configuration
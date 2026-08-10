# AWS Dev Environment Infrastructure (Terraform)

This repository provisions an AWS infrastructure using modularized Terraform configurations. The architecture includes a custom VPC with public and private subnets, an Application Load Balancer (ALB) terminating SSL via a self-signed certificate, and an EC2 web server running Nginx strictly inside a private subnet.

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
            ├── providers.tf       # Provider sources, versions, backend, and region default tags
            ├── main.tf            # Module orchestration and inter-module wiring
            ├── variables.tf       # Environment input definitions
            ├── terraform.tfvars   # Concrete variable values
            ├── outputs.tf         # ALB DNS Name and EC2 Private IP outputs
            └── README.md          # Deployment & verification guide (this file)
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.15.0 (the config enforces this floor via `required_version`)
- An AWS account and credentials with permission to create VPC, EC2, ELBv2, and ACM resources
- AWS CLI configured (`aws configure`) if running locally, **or** rely on the included GitHub Actions OIDC pipeline (see below)

## How to Set Up and Run

### Option A: Deploy via GitHub Actions (recommended)

This repo includes a CI/CD pipeline ([`.github/workflows/terraform.yml`](../../../.github/workflows/terraform.yml)) that authenticates to AWS via OpenID Connect (no static credentials stored in GitHub) and runs `terraform fmt -check`, `plan`, and `apply` automatically on every push to `main` that touches `environments/aws/dev/**` or `modules/aws/**`. It can also be triggered manually via `workflow_dispatch`.

### Option B: Deploy locally

```bash
cd environments/aws/dev
terraform init
terraform plan
terraform apply
```

Terraform state is stored remotely in an S3 backend (bucket `secant78-terraform-state-dev`, provisioned separately via the `bootstrap/` directory) with native S3 state locking (`use_lockfile = true`) to prevent concurrent-apply races.

To tear everything down:

```bash
terraform destroy
```

## Assumptions

- **Self-signed certificate**: as instructed by the exercise, the ALB's HTTPS listener uses a self-signed certificate (generated via the `tls` provider and imported into ACM). Browsers and tools like `curl` will flag this as untrusted by default — this is expected, not a bug. Use `curl -k` or accept the browser warning to connect.
- **Region**: the environment defaults to `us-east-2` (`environments/aws/dev/terraform.tfvars`). This is a deliberate choice, not `us-east-1`, due to account-level service quota constraints (Internet Gateways / Elastic IPs) unrelated to this project's own resource footprint.
- **AMI**: the EC2 instance uses the most recent Amazon Linux 2023 AMI, resolved dynamically via a data source rather than a hardcoded AMI ID, so the instance always boots on a current, patched image.
- **SSH access**: the EC2 security group allows inbound SSH (port 22) from the VPC CIDR block, per the exercise requirements. No SSH key pair is provisioned or attached to the instance, so SSH access is not actually usable as deployed — the security group rule exists to satisfy the stated requirement, but reaching the instance in practice would require adding a key pair and a bastion host or Session Manager, since the instance has no public IP.
- **No high availability**: a single EC2 instance is deployed (as specified), not an Auto Scaling Group, so there's no self-healing if the instance fails.

## How to Verify the Setup

### Quick verify (all checks in one go)

**macOS/Linux/Git Bash:**
```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
EC2_IP=$(terraform output -raw ec2_private_ip)
echo "ALB DNS: $ALB_DNS"
echo "EC2 private IP: $EC2_IP"

curl -kL "https://$ALB_DNS"

echo | openssl s_client -connect "$ALB_DNS:443" -servername "$ALB_DNS" 2>&1 | openssl x509 -noout -subject -issuer -dates

TG_ARN=$(aws elbv2 describe-target-groups --names dev-web-tg --region us-east-2 --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --region us-east-2 --output table
```

**Windows PowerShell:**
```powershell
$albDns = terraform output -raw alb_dns_name
$ec2Ip  = terraform output -raw ec2_private_ip
Write-Host "ALB DNS: $albDns"
Write-Host "EC2 private IP: $ec2Ip"

curl.exe -kL "https://$albDns"

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
$req = [System.Net.HttpWebRequest]::Create("https://$albDns")
$resp = $req.GetResponse()
Write-Host "Subject: $($req.ServicePoint.Certificate.Subject)"
Write-Host "Issuer:  $($req.ServicePoint.Certificate.Issuer)"
$resp.Close()

$tgArn = aws elbv2 describe-target-groups --names dev-web-tg --region us-east-2 --query 'TargetGroups[0].TargetGroupArn' --output text
aws elbv2 describe-target-health --target-group-arn $tgArn --region us-east-2 --output table
```

Both blocks pull the ALB DNS name and target group ARN dynamically from Terraform/AWS, so there are no placeholders to substitute — paste and run.

### Step-by-step breakdown

1. **Get the ALB DNS name** from Terraform output:
   ```bash
   terraform output alb_dns_name
   ```

   Replace `<alb_dns_name>` in the commands below with the actual value returned above (e.g. `dev-web-alb-181249988.us-east-2.elb.amazonaws.com`) — don't paste the placeholder literally.

2. **Confirm the web server is reachable through the ALB** (HTTP redirects to HTTPS):
   ```bash
   curl -kL https://<alb_dns_name>
   ```
   You should see `<h1>Hello from EC2 in Private Subnet (dev)</h1>`. The `-k` flag is required because the certificate is self-signed (see Assumptions above); `-L` follows the HTTP→HTTPS redirect.

   > **Windows PowerShell users**: `curl` and `grep` in this guide refer to the real Unix tools. PowerShell aliases `curl` to `Invoke-WebRequest` (different flags) and has no `grep` at all. Call the real binary explicitly and swap `grep` for `Select-String`:
   > ```powershell
   > curl.exe -kL https://<alb_dns_name>
   > # or the native equivalent:
   > Invoke-WebRequest -Uri https://<alb_dns_name> -SkipCertificateCheck
   > ```

3. **Inspect the self-signed certificate** being served (macOS/Linux, or Git Bash on Windows — requires OpenSSL):
   ```bash
   echo | openssl s_client -connect <alb_dns_name>:443 -servername <alb_dns_name> 2>&1 | openssl x509 -noout -subject -issuer -dates
   ```

   > **Windows PowerShell users**: Windows's built-in `curl.exe` uses Schannel (not OpenSSL) as its TLS backend, so `curl -kv` doesn't print `subject:`/`issuer:` lines the way OpenSSL-linked curl does — `grep`/`Select-String` will find nothing to match. Pull the certificate via .NET instead:
   > ```powershell
   > [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
   > $req = [System.Net.HttpWebRequest]::Create("https://<alb_dns_name>")
   > $resp = $req.GetResponse()
   > $req.ServicePoint.Certificate.Subject
   > $req.ServicePoint.Certificate.Issuer
   > $resp.Close()
   > ```

   Either way, the certificate's `subject` and `issuer` will match (`O=DevOps Assessment, CN=example.com`), confirming it's self-signed rather than CA-issued.

4. **Check target group health** (confirms the ALB considers the EC2 instance healthy). Terraform doesn't output the target group ARN, so look it up via the AWS Console (**EC2 → Target Groups → dev-web-tg → Targets** tab, should show `healthy`), or via CLI:
   ```bash
   aws elbv2 describe-target-groups --names dev-web-tg --query 'TargetGroups[0].TargetGroupArn' --output text
   aws elbv2 describe-target-health --target-group-arn <arn-from-above>
   ```

5. **Confirm the EC2 instance has no public IP** (verifying it's genuinely private):
   ```bash
   terraform output ec2_private_ip
   ```
   This should return only a private (`10.0.x.x`) address.

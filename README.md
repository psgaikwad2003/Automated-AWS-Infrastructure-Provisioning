# Automated AWS 3-Tier Infrastructure Provisioning

<div align="center">

[![Terraform Plan](https://github.com/psgaikwad2003/Automated-AWS-Infrastructure-Provisioning/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/psgaikwad2003/Automated-AWS-Infrastructure-Provisioning/actions/workflows/terraform-plan.yml)
[![Terraform Apply](https://github.com/psgaikwad2003/Automated-AWS-Infrastructure-Provisioning/actions/workflows/terraform-apply.yml/badge.svg)](https://github.com/psgaikwad2003/Automated-AWS-Infrastructure-Provisioning/actions/workflows/terraform-apply.yml)
[![Security Scan](https://github.com/psgaikwad2003/Automated-AWS-Infrastructure-Provisioning/actions/workflows/security-scan.yml/badge.svg)](https://github.com/psgaikwad2003/Automated-AWS-Infrastructure-Provisioning/actions/workflows/security-scan.yml)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.6.0-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-%3E%3D8.0-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Production-grade, fully automated AWS 3-tier cloud infrastructure built with Terraform IaC, configured via Ansible, and deployed through GitHub Actions CI/CD with AWS OIDC authentication.**

[Overview](#-overview) • [Architecture](#-architecture) • [Topology](#-network--subnet-topology) • [Modules](#-modular-terraform-design) • [Ansible](#-ansible-configuration-management) • [CI/CD](#-cicd-pipeline-github-actions) • [Runbooks](#-operational-runbooks) • [Quick Start](#-quick-start) • [Security](#-security--compliance)

</div>

---

## 📖 Overview

This repository provides an enterprise-ready, end-to-end cloud infrastructure solution on Amazon Web Services (AWS). It automates the provisioning, configuration, and continuous deployment of a highly available, secure, and auto-scaling 3-tier web application architecture.

### Key Highlights
- **Zero-Trust Network Isolation**: Public web tier, private application tier, and completely isolated database subnets with strict least-privilege Security Groups.
- **High Availability & Fault Tolerance**: Deployed across dual Availability Zones (`us-east-1a` and `us-east-1b`) with Multi-AZ RDS failover and Auto Scaling Groups.
- **Enterprise IaC**: Modular Terraform with remote S3 backend state locking via DynamoDB, reusable submodules, and multi-environment management (`dev` vs. `prod`).
- **Automated Configuration Management**: Dynamic AWS inventory with Ansible playbooks for OS hardening, Nginx reverse proxy configuration, Node.js runtime, and CloudWatch Agent setup.
- **Keyless CI/CD with OIDC**: GitHub Actions workflows authenticated to AWS through OpenID Connect (OIDC) — no long-lived static AWS access keys.

---

## 📐 Architecture

<div align="center">
  <img src="docs/images/architecture.svg" alt="AWS 3-Tier Automated Architecture Diagram" width="100%">
</div>

### Architectural Traffic Flow

1. **Ingress**: External clients send HTTPS/HTTP traffic to the internet-facing **External Application Load Balancer (ALB)** residing in public subnets across 2 Availability Zones.
2. **Web Tier**: The External ALB routes requests to the **Web Auto Scaling Group (Nginx)**. Nginx terminates client connections, handles caching, rate limiting, and forwards dynamic requests.
3. **Internal Routing**: Requests pass through an **Internal ALB** located in private application subnets, ensuring backend services are never directly accessible from the public internet.
4. **App Tier**: The Internal ALB balances loads across the **App Auto Scaling Group (Node.js/Microservices)** running inside private subnets. Instances scale dynamically based on CloudWatch CPU/memory metrics.
5. **Data Tier**: Applications query an **Amazon RDS MySQL 8.0 Multi-AZ** cluster. The primary database processes writes in `us-east-1a` and synchronously replicates to a hot standby in `us-east-1b`. Database credentials are randomly generated and securely stored in **AWS SSM Parameter Store**.
6. **Management & Outbound**: Administrators access private instances securely via **AWS Systems Manager (SSM) Session Manager** or through a hardened **Bastion Host**. Private instances fetch updates and external dependencies via an **AWS NAT Gateway**.

---

## 🌐 Network & Subnet Topology

VPC CIDR Block: `10.0.0.0/16` in Region `us-east-1`

| Tier | Subnet Type | CIDR Block | Availability Zone | Purpose | Route Target |
|:-----|:------------|:-----------|:------------------|:--------|:-------------|
| **Web** | Public Subnet 1 | `10.0.0.0/20` | `us-east-1a` | External ALB, Bastion Host, NAT GW | Internet Gateway (`igw`) |
| **Web** | Public Subnet 2 | `10.0.16.0/20` | `us-east-1b` | External ALB (HA Standby) | Internet Gateway (`igw`) |
| **App** | Private Subnet 1 | `10.0.128.0/20` | `us-east-1a` | Internal ALB, App ASG Instances | NAT Gateway (`nat-gw`) |
| **App** | Private Subnet 2 | `10.0.144.0/20` | `us-east-1b` | Internal ALB, App ASG Instances | NAT Gateway (`nat-gw`) |
| **Database** | Private Subnet 3 | `10.0.160.0/20` | `us-east-1a` | RDS MySQL Primary Instance | Local VPC Only (Isolated) |
| **Database** | Private Subnet 4 | `10.0.176.0/20` | `us-east-1b` | RDS MySQL Multi-AZ Standby | Local VPC Only (Isolated) |

---

## 🗂️ Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml       # PR validation, fmt check & plan commentary
│       ├── terraform-apply.yml      # Automated deployment to dev/prod on push
│       └── terraform-destroy.yml    # Manual teardown workflow dispatch
├── ansible/
│   ├── ansible.cfg                  # Ansible base settings & SSH configuration
│   ├── inventory/
│   │   ├── aws_ec2.yml              # Dynamic AWS EC2 inventory plugin
│   │   └── group_vars/              # Environment-specific configuration
│   ├── playbooks/
│   │   ├── site.yml                 # Master playbook (common + web + app)
│   │   ├── webservers.yml           # Web tier configuration playbook
│   │   └── appservers.yml           # App tier configuration playbook
│   └── roles/
│       ├── common/                  # Hardening, CloudWatch Agent, log rotation
│       ├── webserver/               # Nginx reverse proxy & health endpoints
│       └── appserver/               # Node.js runtime & systemd service
├── docs/
│   ├── architecture.md              # Deep-dive architecture design guide
│   └── images/
│       └── architecture.svg         # High-resolution vector architecture diagram
├── scripts/
│   ├── bootstrap.sh                 # S3 state bucket & DynamoDB lock setup
│   ├── deploy.sh                    # Automated deployment orchestration script
│   └── destroy.sh                   # Safe teardown script
├── terraform/
│   ├── environments/
│   │   ├── dev/                     # Dev environment (t3.micro, single NAT)
│   │   └── prod/                    # Prod environment (Multi-AZ, deletion protection)
│   ├── modules/
│   │   ├── alb/                     # External & internal Application Load Balancers
│   │   ├── autoscaling/             # ASG, launch templates, CloudWatch scaling
│   │   ├── ec2/                     # Bastion host instance
│   │   ├── iam/                     # EC2 instance profiles & OIDC roles
│   │   ├── rds/                     # MySQL 8.0 Multi-AZ database & SSM secrets
│   │   ├── s3/                      # S3 assets bucket & state storage
│   │   ├── security-groups/         # Tiered security group rules
│   │   └── vpc/                     # VPC, subnets, route tables, IGW, NAT
│   ├── backend.tf                   # Remote state backend declaration
│   ├── main.tf                      # Root orchestration module
│   ├── outputs.tf                   # Root output definitions
│   ├── providers.tf                 # AWS and Random provider definitions
│   ├── terraform.tfvars.example     # Sample variables reference
│   └── variables.tf                 # Global variable inputs
├── Makefile                         # Unified automation commands
├── LICENSE                          # MIT License
└── README.md                        # Documentation
```

---

## 🧩 Modular Terraform Design

| Module | Location | Purpose | Key Managed Resources |
|:-------|:---------|:--------|:----------------------|
| **`vpc`** | `terraform/modules/vpc` | Networking Layer | VPC, 6 Subnets (Public/Private), IGW, NAT GW, Elastic IPs, Route Tables |
| **`security-groups`** | `terraform/modules/security-groups` | Traffic Isolation | ALB SGs, Web SG, App SG, Database SG, Bastion SG |
| **`alb`** | `terraform/modules/alb` | Traffic Balancing | External ALB, Internal ALB, Target Groups, Health Checks, Listeners |
| **`autoscaling`** | `terraform/modules/autoscaling` | Dynamic Compute | Launch Templates, Web ASG, App ASG, Target Tracking Scaling Policies |
| **`rds`** | `terraform/modules/rds` | Persistent Database | RDS MySQL Multi-AZ, Subnet Group, Random Password, SSM Parameter |
| **`iam`** | `terraform/modules/iam` | Permissions & Security | Instance Roles, SSM Managed Policy, CloudWatch Logs & S3 Access Policies |
| **`ec2`** | `terraform/modules/ec2` | Secure Access Point | Bastion Host EC2 instance in public subnet |
| **`s3`** | `terraform/modules/s3` | Object & State Storage | App Assets S3 Bucket, State Bucket, Lifecycle Rules, Public Access Blocks |
| **`waf`** | `terraform/modules/waf` | Edge Protection | AWS WAFv2 Web ACL, Rate-based Rules, AWS Managed Rules (CRS, Bad Inputs, IP Reputation) |
| **`monitoring`** | `terraform/modules/monitoring` | Observability & Alerting | Cross-Tier CloudWatch Dashboard, SNS Alert Topic & Metric Alarms (5xx, Disk, CPU) |


---

## ⚙️ Ansible Configuration Management

Ansible dynamically discovers instances using the AWS EC2 plugin and provisions packages, configuration files, and services.

```bash
# 1. Install prerequisites
pip install ansible boto3 botocore
ansible-galaxy collection install amazon.aws

# 2. Test dynamic inventory connectivity
cd ansible && ansible all -m ping -i inventory/aws_ec2.yml

# 3. Execute end-to-end configuration
ansible-playbook playbooks/site.yml -i inventory/aws_ec2.yml
```

### Roles Breakdown
- **`common`**: Updates system packages, sets up NTP time sync, installs CloudWatch Agent, and configures daily log rotation.
- **`webserver`**: Installs Nginx, generates reverse proxy configuration forwarding upstream traffic to the internal ALB, and creates `/health` probe endpoints.
- **`appserver`**: Sets up Node.js runtime environment, deploys the backend microservice, and creates a managed `systemd` daemon.

---

## 🔄 CI/CD Pipeline (GitHub Actions)

The deployment pipeline is fully automated using GitHub Actions workflows with zero static AWS credentials (powered by AWS OIDC):

```
Pull Request (dev/prod) ──► terraform fmt -check ──► terraform validate ──► terraform plan ──► PR Comment
                                                                                                  │
Merge to develop/main   ──► terraform init       ──► terraform apply    ──► Capture Outputs ◄────┘
```

| Workflow | Trigger | Functionality |
|:---------|:--------|:--------------|
| **`terraform-plan.yml`** | PR to `main` or `develop` | Runs format check, runs `terraform validate`, calculates `terraform plan`, and automatically comments full diff on the PR. |
| **`terraform-apply.yml`** | Push to `main` or `develop` | Dynamically detects environment (`dev` for develop, `prod` for main) and safely applies changes. |
| **`terraform-destroy.yml`** | Manual `workflow_dispatch` | Provides controlled, environment-specific destruction with confirmation safeguards. |
| **`security-scan.yml`** | PR, push & weekly cron | Automated DevSecOps scanner running Checkov, Trivy, and Ansible-lint. |

---

## 📚 Operational Runbooks

Production-grade operating procedures and incident recovery guides are maintained in the [`docs/runbooks/`](docs/runbooks/) directory:

- 🚨 **[Disaster Recovery Runbook](docs/runbooks/disaster-recovery.md)**: Procedures for multi-AZ failovers, point-in-time recovery (PITR) for RDS, auto scaling recovery, and DynamoDB lock release.
- 🔄 **[Zero-Downtime Deployment Runbook](docs/runbooks/zero-downtime-deployment.md)**: Rolling instance refresh procedures, graceful connection draining, canary release strategies, and rollback protocols.

---


## 🚀 Quick Start

### 1. Prerequisites
- **Terraform** >= 1.6.0
- **AWS CLI** >= 2.x configured (`aws configure` or environment credentials)
- **Make** (`make --version`)
- **Python** >= 3.9 & **Ansible** >= 8.x

### 2. Bootstrap State Backend
Initialize the remote S3 bucket and DynamoDB locking table before provisioning:

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh my-custom-state-bucket us-east-1
```

*Note: Update `terraform/backend.tf` and environment backend blocks with the printed bucket name.*

### 3. Deploy Using Makefile
Easily manage environments with standard `make` targets:

```bash
# Deploy to Development
make init ENVIRONMENT=dev
make plan ENVIRONMENT=dev
make apply ENVIRONMENT=dev

# Run Ansible configuration
make ansible-ping
make ansible-deploy

# Deploy to Production
make init ENVIRONMENT=prod
make plan ENVIRONMENT=prod
make apply ENVIRONMENT=prod
```

### 4. Teardown
```bash
# Destroy Development Infrastructure
make destroy ENVIRONMENT=dev
```

---

## 🔒 Security & Compliance

- **No Stored Plaintext Passwords**: Database master passwords are created via Terraform's `random_password` provider and directly written to **AWS Systems Manager Parameter Store** (`SecureString`).
- **Encrypted Storage**: RDS instances are encrypted using AWS KMS (`AES-256`); S3 state and asset buckets use server-side encryption with versioning and public access blocks.
- **Least-Privilege Security Groups**:
  - Web ALB: Allows HTTP (80) and HTTPS (443) from `0.0.0.0/0`.
  - Web ASG: Allows port 80 strictly from the Web ALB SG.
  - Internal ALB: Allows traffic strictly from the Web ASG SG.
  - App ASG: Allows application port strictly from the Internal ALB SG.
  - RDS MySQL: Allows port 3306 strictly from the App ASG SG.
- **SSM Session Manager**: Bastion and private EC2 instances have IAM instance profiles attached with `AmazonSSMManagedInstanceCore` to avoid exposing open SSH ports to the public internet.

---

## 📊 Environment Sizing Matrix

| Feature | Development (`dev`) | Production (`prod`) |
|:--------|:--------------------|:--------------------|
| **Web ASG Instances** | 1 desired (min 1, max 3) `t3.micro` | 2 desired (min 2, max 6) `t3.medium` |
| **App ASG Instances** | 1 desired (min 1, max 3) `t3.micro` | 2 desired (min 2, max 6) `t3.large` |
| **RDS Database** | `db.t3.micro` (Single-AZ) | `db.t3.medium` (Multi-AZ Failover) |
| **Deletion Protection** | Disabled | Enabled |
| **Estimated Cost** | ~$108 / month | ~$380 / month |

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:
1. Fork this repository.
2. Create your feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request — the automated CI pipeline will run formatting checks and generate a Terraform execution plan.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

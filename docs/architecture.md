# Architecture Documentation

## Overview

This document describes the AWS 3-tier architecture provisioned by this project.

## Architecture Diagram

```
                          ┌─────────────────────────────────────────────────┐
                          │                  AWS us-east-1                  │
                          │                                                  │
         Internet         │  ┌──────────────┐  ┌──────────────┐            │
            │             │  │  us-east-1a  │  │  us-east-1b  │            │
            ▼             │  │              │  │              │            │
    ┌───────────────┐     │  │              │  │              │            │
    │ External ALB  │     │  │              │  │              │            │
    │ (internet-    │     │  └──────────────┘  └──────────────┘            │
    │  facing)      │     │                                                  │
    └───────┬───────┘     └─────────────────────────────────────────────────┘
            │
            ▼ HTTP/HTTPS
┌─────────────────────────────────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16                                                       │
│                                                                          │
│  ┌──── Public Subnets (Web Tier) ──────────────────────────────────┐   │
│  │  10.0.0.0/20 (1a)         10.0.16.0/20 (1b)                    │   │
│  │  ┌─────────────┐          ┌─────────────┐                       │   │
│  │  │  Web EC2    │          │  Web EC2    │  ← Auto Scaling Group │   │
│  │  │  (nginx)    │          │  (nginx)    │                       │   │
│  │  └─────────────┘          └─────────────┘                       │   │
│  │                                                                   │   │
│  │  ┌─────────────┐          ┌─────────────┐                       │   │
│  │  │   Bastion   │          │ NAT Gateway │                       │   │
│  │  │    Host     │          │             │                       │   │
│  │  └─────────────┘          └─────────────┘                       │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                         │                                                │
│                 Internal ALB                                             │
│                         │                                                │
│  ┌──── Private Subnets (App Tier) ─────────────────────────────────┐   │
│  │  10.0.128.0/20 (1a)       10.0.144.0/20 (1b)                   │   │
│  │  ┌─────────────┐          ┌─────────────┐                       │   │
│  │  │  App EC2    │          │  App EC2    │  ← Auto Scaling Group │   │
│  │  │ (Node.js)   │          │ (Node.js)   │                       │   │
│  │  └─────────────┘          └─────────────┘                       │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                         │                                                │
│                      MySQL 8.0                                           │
│                         │                                                │
│  ┌──── Private Subnets (DB Tier) ──────────────────────────────────┐   │
│  │  10.0.160.0/20 (1a)       10.0.176.0/20 (1b)                   │   │
│  │  ┌─────────────────────────────────────────┐                    │   │
│  │  │          RDS MySQL 8.0 Multi-AZ          │                   │   │
│  │  │   Primary (1a)   |   Standby (1b)        │                   │   │
│  │  └─────────────────────────────────────────┘                    │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### VPC (10.0.0.0/16)

The Virtual Private Cloud provides network isolation for all resources.

| Property            | Value           |
|---------------------|-----------------|
| CIDR Block          | 10.0.0.0/16     |
| DNS Hostnames       | Enabled         |
| DNS Support         | Enabled         |
| Region              | us-east-1       |
| Availability Zones  | 1a and 1b       |

### Internet Gateway

Provides internet access for resources in public subnets.

### NAT Gateway

- Located in Public Subnet 1 (us-east-1a)
- Provides outbound internet access for private subnets
- Has a static Elastic IP
- All private subnets route 0.0.0.0/0 through this NAT

### Subnets

#### Public Subnets (Web Tier)

| Subnet   | CIDR           | AZ          | Purpose                     |
|----------|----------------|-------------|-----------------------------|
| Public 1 | 10.0.0.0/20    | us-east-1a  | Web servers, Bastion, NAT   |
| Public 2 | 10.0.16.0/20   | us-east-1b  | Web servers (HA)            |

#### Private Subnets (App Tier)

| Subnet    | CIDR            | AZ          | Purpose          |
|-----------|-----------------|-------------|------------------|
| Private 1 | 10.0.128.0/20   | us-east-1a  | App servers      |
| Private 2 | 10.0.144.0/20   | us-east-1b  | App servers (HA) |

#### Private Subnets (DB Tier)

| Subnet    | CIDR            | AZ          | Purpose           |
|-----------|-----------------|-------------|-------------------|
| Private 3 | 10.0.160.0/20   | us-east-1a  | RDS Primary       |
| Private 4 | 10.0.176.0/20   | us-east-1b  | RDS Standby (HA)  |

### Route Tables

| Route Table   | Destination | Target          |
|---------------|-------------|-----------------|
| public-rtb    | 0.0.0.0/0   | Internet Gateway|
| private-rtb   | 0.0.0.0/0   | NAT Gateway     |

---

## Security Groups

| Security Group  | Allows Inbound From         | Ports           |
|-----------------|-----------------------------|-----------------|
| `bastion-sg`    | bastion_allowed_cidr        | TCP 22          |
| `web-alb-sg`    | 0.0.0.0/0                   | TCP 80, 443     |
| `webserver-sg`  | web-alb-sg, bastion-sg      | TCP 80, 443, 22 |
| `app-alb-sg`    | webserver-sg                | TCP 80, 8080    |
| `appserver-sg`  | app-alb-sg, bastion-sg      | TCP 8080, 22    |
| `database-sg`   | appserver-sg                | TCP 3306, 5432  |

All security groups allow all outbound traffic (0.0.0.0/0).

---

## Load Balancers

### External ALB (Web Tier)

- **Type**: Application Load Balancer (internet-facing)
- **Scheme**: internet-facing
- **Subnets**: Public Subnet 1 & 2
- **Listeners**:
  - Port 80 → Redirect to HTTPS (301)
  - Port 443 → Forward to web target group (HTTPS if certificate configured)
- **Target Group**: Web ASG instances on port 80
- **Health Check**: GET /health → 200 OK

### Internal ALB (App Tier)

- **Type**: Application Load Balancer (internal)
- **Scheme**: internal
- **Subnets**: Private App Subnet 1 & 2
- **Listeners**:
  - Port 8080 → Forward to app target group
- **Target Group**: App ASG instances on port 8080
- **Health Check**: GET /health → 200 OK

---

## Auto Scaling Groups

### Web ASG

| Property         | Dev      | Prod     |
|------------------|----------|----------|
| Instance Type    | t3.micro | t3.medium|
| Min              | 1        | 2        |
| Max              | 3        | 6        |
| Desired          | 1        | 2        |
| Launch Template  | nginx    | nginx    |
| Scale Up at CPU  | ≥ 70%    | ≥ 70%    |
| Scale Down at CPU| ≤ 20%    | ≤ 20%    |

### App ASG

| Property         | Dev      | Prod     |
|------------------|----------|----------|
| Instance Type    | t3.micro | t3.large |
| Min              | 1        | 2        |
| Max              | 3        | 6        |
| Desired          | 1        | 2        |
| Launch Template  | Node.js  | Node.js  |
| Scale Up at CPU  | ≥ 70%    | ≥ 70%    |
| Scale Down at CPU| ≤ 20%    | ≤ 20%    |

---

## RDS MySQL 8.0

| Property              | Dev          | Prod          |
|-----------------------|--------------|---------------|
| Instance Class        | db.t3.micro  | db.t3.medium  |
| Multi-AZ              | Yes          | Yes           |
| Storage Type          | gp3          | gp3           |
| Allocated Storage     | 20 GB        | 20–100 GB     |
| Encryption            | Yes (AES256) | Yes (AES256)  |
| Backup Retention      | 7 days       | 7 days        |
| Deletion Protection   | No           | Yes           |
| Password Storage      | SSM Parameter Store (SecureString) | SSM Parameter Store |
| Enhanced Monitoring   | 60s interval | 60s interval  |
| Performance Insights  | 7 days       | 7 days        |

---

## IAM

### EC2 Instance Role Permissions

| Permission Set          | Policy                               |
|-------------------------|--------------------------------------|
| SSM Session Manager     | AmazonSSMManagedInstanceCore (managed)|
| CloudWatch Agent        | CloudWatchAgentServerPolicy (managed)|
| S3 Read (app bucket)    | Custom inline policy                 |
| CloudWatch Logs Write   | Custom inline policy                 |
| SSM Parameter Get       | Custom inline policy (scoped to project path)|

---

## Data Flow

```
User Request
    │
    ▼
[Route 53] (optional)
    │
    ▼
[External ALB] — port 80 → redirect 443
    │              port 443 → Web Target Group
    ▼
[Web EC2 / nginx]
    │  /api/* → proxy_pass
    ▼
[Internal ALB] — port 8080
    │
    ▼
[App EC2 / Node.js]
    │  DB queries
    ▼
[RDS MySQL 8.0]
```

---

## Monitoring & Observability

- **CloudWatch Metrics**: CPU, memory (via CW agent) for all EC2 instances
- **CloudWatch Alarms**: CPU thresholds drive ASG scale-up/scale-down
- **CloudWatch Logs**: nginx access/error logs, app logs, VPC flow logs
- **RDS Enhanced Monitoring**: Process-level metrics every 60 seconds
- **RDS Performance Insights**: Query performance tracking (7-day retention)
- **ALB Access Logs**: Optional; configure S3 bucket in ALB module


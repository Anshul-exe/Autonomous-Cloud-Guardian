# 🛡️ Autonomous Cloud Guardian

> **A FinOps + DevSecOps Platform** — Automatically secures code and optimizes cloud costs

[![CI](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/ci.yml/badge.svg)](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/ci.yml)
[![Security Scans](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/security.yml/badge.svg)](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/security.yml)
[![CD](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/cd.yml/badge.svg)](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/cd.yml)

---

## 📋 Overview

Autonomous Cloud Guardian demonstrates enterprise-grade DevSecOps and FinOps practices through a real-world implementation:

| Pillar             | Implementation                                                        |
| ------------------ | --------------------------------------------------------------------- |
| **DevSecOps**      | Automated SAST (Semgrep) + Container scanning (Trivy) in CI/CD        |
| **FinOps**         | Lambda-based idle resource detection, auto-stop, and savings tracking |
| **Infrastructure** | Terraform-managed AWS resources with least-privilege IAM              |
| **Observability**  | CloudWatch dashboards for cost and security metrics                   |

---

## 🏗️ Architecture

```mermaid
flowchart TB
    subgraph "GitHub"
        A[Push to Main] --> B[CI Workflow]
        B --> B1[Lint & Build]
        B1 --> B2[Build Docker Image]
        B2 --> B3[Save as Artifact]

        B3 --> C[Security Workflow]
        C --> C1[Semgrep SAST]
        C --> C2[Trivy Container Scan]
        C1 & C2 --> C3[SARIF → GitHub Security]

        B3 --> D[CD Workflow]
        D --> D1{Security Passed?}
        D1 -->|Yes| D2[Push to GHCR]
        D1 -->|No| D3[❌ Block Deploy]
        D2 --> D4[Deploy via SSH]
    end

    subgraph "AWS Infrastructure"
        SSM[(SSM Parameter Store)]
        D4 --> |Get EC2 IP| SSM
        D4 --> EC2[EC2 Instance]
        EC2 --> |Docker Pull| GHCR[GHCR Registry]
        EC2 --> APP[Node.js App :3000]

        EB[EventBridge] -->|Hourly| LAMBDA[Lambda: stop-idle]
        LAMBDA --> |Query CPU| CW[CloudWatch Metrics]
        LAMBDA -->|CPU < 5%| EC2
        LAMBDA -->|Stop Instance| EC2
    end

    subgraph "Notifications"
        LAMBDA --> SLACK[Slack Webhook]
        SLACK --> ALERT[🛑 Instance Stopped Alert]
    end

    subgraph "IaC"
        TF[Terraform] --> |Provisions| EC2
        TF --> |Provisions| LAMBDA
        TF --> |Provisions| SSM
        TF --> |Provisions| EB
    end
```

### Component Flow

| Flow       | Description                                                                   |
| ---------- | ----------------------------------------------------------------------------- |
| **CI/CD**  | Push → Build → Scan → Deploy to EC2 via SSH                                   |
| **FinOps** | EventBridge (hourly) → Lambda checks CPU → Stops idle instances → Slack alert |
| **IaC**    | Terraform manages all AWS resources with `Project: cloud-guardian` tagging    |

---

## 🔐 DevSecOps Pipeline

### Security Scanning Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   CI Build  │────▶│   Semgrep   │────▶│   Trivy     │
│  (Lint/Test)│     │   (SAST)    │     │ (Container) │
└─────────────┘     └─────────────┘     └─────────────┘
                           │                   │
                           ▼                   ▼
                    ┌─────────────────────────────┐
                    │   GitHub Security Tab       │
                    │   (SARIF Reports)           │
                    └─────────────────────────────┘
```

### Security Tools

| Tool          | Purpose                                    | Integration                                                                 |
| ------------- | ------------------------------------------ | --------------------------------------------------------------------------- |
| **Semgrep**   | Static Application Security Testing (SAST) | Custom rules in `.semgrep.yml` detecting `eval()`, `exec()`, code injection |
| **Trivy**     | Container vulnerability scanning           | Scans Docker image for CVEs in OS packages and dependencies                 |
| **ESLint**    | Code quality + security linting            | `eslint-plugin-security` for JS-specific vulnerabilities                    |
| **npm audit** | Dependency vulnerability check             | Blocks on HIGH severity issues                                              |

### Custom Semgrep Rules

```yaml
# Detects dangerous patterns
- eval(...) # Code injection
- exec(...) # Command injection
- new Function(...) # Dynamic code execution
```

---

## 💰 FinOps Automation

### Idle Resource Detection

```
┌──────────────────┐
│   EventBridge    │
│   (Every Hour)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│  Lambda Function │────▶│ CloudWatch Metrics│
│  (stop-idle)     │     │  (CPU Utilization)│
└────────┬─────────┘     └──────────────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│  CPU < 5% avg    │─Yes─▶│  Stop Instance   │
│  (last hour)?    │      │  + Slack Alert   │
└──────────────────┘     └──────────────────┘
```

### How It Works

1. **EventBridge** triggers Lambda every hour
2. **Lambda** queries CloudWatch for average CPU utilization (last hour)
3. Instances tagged with `Project: cloud-guardian` and avg CPU < 5% are stopped
4. **Slack notification** sent with instance details and estimated savings
5. Instances can be restarted manually when needed

### Cost Optimization Features

- ✅ Auto-stop idle EC2 instances (CPU < 5%)
- ✅ Tag-based targeting (`Project: cloud-guardian`)
- ✅ Slack notifications with estimated savings
- 🔲 Cost report Lambda (AWS Cost Explorer)
- 🔲 CloudWatch dashboard for visibility

---

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.0
- Docker
- Node.js 18+ (for local development)

### Deploy Infrastructure

```bash
# Clone repository
git clone https://github.com/Anshul-exe/Autonomous-Cloud-Guardian.git
cd Cloud-Guardian

# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f terraform/Cloud-Guardian.pem -N ""
mv terraform/Cloud-Guardian.pem.pub terraform/Cloud-Guardian.pub

# Deploy with Terraform
cd terraform
terraform init
terraform plan
terraform apply
```

### Run Locally

```bash
cd app
npm install
npm run dev
# API available at http://localhost:3000
```

### API Endpoints

| Endpoint      | Description                          |
| ------------- | ------------------------------------ |
| `GET /`       | Application info                     |
| `GET /health` | Health check with uptime             |
| `GET /hello`  | Hello world                          |
| `GET /load`   | Real-time CPU and memory utilization |

---

## 📁 Project Structure

```
Cloud-Guardian/
├── app/
│   ├── index.js              # Express.js API with health/load endpoints
│   ├── Dockerfile            # Multi-stage Docker build
│   └── package.json          # Dependencies
├── lambda/
│   └── package/
│       └── stop_idle_instances.py  # FinOps Lambda function
├── terraform/
│   ├── main.tf               # EC2, Security Groups, SSM
│   ├── lambda.tf             # Lambda, EventBridge, IAM roles
│   ├── variables.tf          # Configuration variables
│   ├── observability.tf      # cloudwatch observability
│   └── outputs.tf            # Deployment outputs
├── .github/workflows/
│   ├── ci.yml                # Build, lint, test, artifact creation
│   ├── security.yml          # Semgrep SAST + Trivy container scan
│   └── cd.yml                # Deploy to EC2 via SSH
└── .semgrep.yml              # Custom security rules
```

---

## 🛠️ Technologies

### Infrastructure & Cloud

![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)

### CI/CD & Security

![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=github-actions&logoColor=white)
![Semgrep](https://img.shields.io/badge/Semgrep-4B11A8?style=flat&logo=semgrep&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-1904DA?style=flat&logo=aqua&logoColor=white)

### Application

![Node.js](https://img.shields.io/badge/Node.js-339933?style=flat&logo=node.js&logoColor=white)
![Express](https://img.shields.io/badge/Express-000000?style=flat&logo=express&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)

---

## 📊 Skills Demonstrated

| Category                   | Skills                                                                   |
| -------------------------- | ------------------------------------------------------------------------ |
| **Infrastructure as Code** | Terraform modules, state management, AWS provider                        |
| **CI/CD**                  | GitHub Actions, multi-stage pipelines, artifact management               |
| **DevSecOps**              | SAST integration, container scanning, SARIF reports, shift-left security |
| **FinOps**                 | Cost optimization automation, idle resource detection, savings tracking  |
| **Cloud Services**         | EC2, Lambda, CloudWatch, EventBridge, IAM, SSM Parameter Store           |
| **Containerization**       | Docker, GHCR, image scanning, multi-stage builds                         |
| **Serverless**             | Lambda functions, event-driven architecture                              |
| **Monitoring**             | CloudWatch dashboards, metrics, alarms                                   |

---

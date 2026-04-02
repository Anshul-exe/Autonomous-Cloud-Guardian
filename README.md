# 🛡️ Autonomous Cloud Guardian

> **A FinOps + DevSecOps Platform** — Automatically secures code and optimizes cloud costs

<!--[![CI](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/ci.yml/badge.svg)](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/ci.yml)
[![Security Scans](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/security.yml/badge.svg)](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/security.yml)
[![CD](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/cd.yml/badge.svg)](https://github.com/Anshul-exe/Autonomous-Cloud-Guardian/actions/workflows/cd.yml)-->

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
    subgraph GH["&nbsp;&nbsp;☁️ GITHUB ACTIONS PIPELINE &nbsp;&nbsp;"]
        direction TB
        A["🚀 <b>Push to Main</b>"]
        
        subgraph CI["&nbsp; 🔨 CI Workflow &nbsp;"]
            direction LR
            B1["📋 Lint &<br/>Build"]
            B2["🐳 Build<br/>Docker Image"]
            B3["💾 Save<br/>Artifact"]
            B1 --> B2 --> B3
        end
        
        subgraph SEC["&nbsp; 🔒 Security Workflow &nbsp;"]
            direction LR
            C1["🔍 Semgrep<br/>SAST Scan"]
            C2["🛡️ Trivy<br/>Container Scan"]
            C3["📊 SARIF →<br/>Security Tab"]
            C1 --> C3
            C2 --> C3
        end
        
        subgraph CD["&nbsp; 🚢 CD Workflow &nbsp;"]
            direction LR
            D1{"✅ Security<br/>Passed?"}
            D2["📦 Push to<br/>GHCR"]
            D3["❌ Block<br/>Deploy"]
            D4["🔗 Deploy<br/>via SSH"]
            D1 -->|"Yes"| D2
            D1 -->|"No"| D3
            D2 --> D4
        end
        
        A --> CI
        CI --> SEC
        CI --> CD
    end

    subgraph AWS["&nbsp;&nbsp;☁️ AWS INFRASTRUCTURE &nbsp;&nbsp;"]
        direction TB
        
        subgraph COMPUTE["&nbsp; 💻 Compute Layer &nbsp;"]
            direction LR
            SSM[("🔑 SSM<br/>Parameter Store")]
            EC2["🖥️ <b>EC2 Instance</b><br/>Amazon Linux 2"]
            APP["⚡ Node.js App<br/>Express :3000"]
            EC2 --> APP
        end
        
        subgraph FINOPS["&nbsp; 💰 FinOps Automation &nbsp;"]
            direction LR
            EB["⏰ EventBridge<br/>Hourly Trigger"]
            LAMBDA["⚙️ <b>Lambda</b><br/>stop-idle-instances"]
            CW["📈 CloudWatch<br/>CPU Metrics"]
            EB --> LAMBDA
            LAMBDA --> CW
        end
        
        LAMBDA -->|"CPU < 5%<br/>Stop Instance"| EC2
    end

    subgraph NOTIFY["&nbsp;&nbsp;📢 NOTIFICATIONS &nbsp;&nbsp;"]
        SLACK["💬 <b>Slack Webhook</b>"]
        ALERT["🛑 Instance Stopped<br/>+ Cost Savings Alert"]
        SLACK --> ALERT
    end

    subgraph IAC["&nbsp;&nbsp;🏗️ INFRASTRUCTURE AS CODE &nbsp;&nbsp;"]
        TF["🟪 <b>Terraform</b><br/>AWS Provider v6"]
    end

    D4 -->|"Get EC2 IP"| SSM
    D4 -->|"SSH Deploy"| EC2
    EC2 -.->|"Docker Pull"| GHCR["📦 GHCR<br/>Registry"]
    
    LAMBDA -->|"Notify"| SLACK
    
    TF -.->|"Provisions"| EC2
    TF -.->|"Provisions"| LAMBDA
    TF -.->|"Provisions"| SSM
    TF -.->|"Provisions"| EB
    TF -.->|"Provisions"| CW

    %% Styling
    classDef github fill:#24292e,stroke:#58a6ff,stroke-width:2px,color:#fff
    classDef aws fill:#232f3e,stroke:#ff9900,stroke-width:2px,color:#fff
    classDef security fill:#1a1a2e,stroke:#e94560,stroke-width:2px,color:#fff
    classDef finops fill:#0d2137,stroke:#00d4aa,stroke-width:2px,color:#fff
    classDef notify fill:#2d1b4e,stroke:#a855f7,stroke-width:2px,color:#fff
    classDef terraform fill:#1a1a2e,stroke:#7b42bc,stroke-width:2px,color:#fff
    classDef action fill:#0d419d,stroke:#58a6ff,stroke-width:2px,color:#fff
    classDef decision fill:#854d0e,stroke:#fbbf24,stroke-width:2px,color:#fff
    classDef danger fill:#7f1d1d,stroke:#ef4444,stroke-width:2px,color:#fff
    
    class GH github
    class AWS,COMPUTE aws
    class SEC security
    class FINOPS finops
    class NOTIFY notify
    class IAC,TF terraform
    class A,B1,B2,B3,D2,D4 action
    class D1 decision
    class D3 danger
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
![EC2](https://img.shields.io/badge/EC2-FF9900?style=flat&logo=amazon-ec2&logoColor=white)
![Lambda](https://img.shields.io/badge/Lambda-FF9900?style=flat&logo=aws-lambda&logoColor=white)
![CloudWatch](https://img.shields.io/badge/CloudWatch-FF4F8B?style=flat&logo=amazon-cloudwatch&logoColor=white)
![EventBridge](https://img.shields.io/badge/EventBridge-FF4F8B?style=flat&logo=amazon-aws&logoColor=white)
![IAM](https://img.shields.io/badge/IAM-DD344C?style=flat&logo=amazon-aws&logoColor=white)
![SSM](https://img.shields.io/badge/SSM_Parameter_Store-232F3E?style=flat&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Alpine Linux](https://img.shields.io/badge/Alpine_Linux-0D597F?style=flat&logo=alpine-linux&logoColor=white)

### CI/CD & DevOps

![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=github-actions&logoColor=white)
![GHCR](https://img.shields.io/badge/GHCR-181717?style=flat&logo=github&logoColor=white)
![SSH](https://img.shields.io/badge/SSH-4D4D4D?style=flat&logo=openssh&logoColor=white)

### Security & Code Quality

![Semgrep](https://img.shields.io/badge/Semgrep-4B11A8?style=flat&logo=semgrep&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-1904DA?style=flat&logo=aqua&logoColor=white)
![ESLint](https://img.shields.io/badge/ESLint-4B32C3?style=flat&logo=eslint&logoColor=white)
![npm audit](https://img.shields.io/badge/npm_audit-CB3837?style=flat&logo=npm&logoColor=white)
![SARIF](https://img.shields.io/badge/SARIF-0078D4?style=flat&logo=github&logoColor=white)
![CodeQL](https://img.shields.io/badge/CodeQL-000000?style=flat&logo=github&logoColor=white)

### Application & Runtime

![Node.js](https://img.shields.io/badge/Node.js_20-339933?style=flat&logo=node.js&logoColor=white)
![Express](https://img.shields.io/badge/Express_5-000000?style=flat&logo=express&logoColor=white)
![Python](https://img.shields.io/badge/Python_3.9-3776AB?style=flat&logo=python&logoColor=white)
![Boto3](https://img.shields.io/badge/Boto3-232F3E?style=flat&logo=amazon-aws&logoColor=white)

### Notifications & Monitoring

![Slack](https://img.shields.io/badge/Slack_Webhooks-4A154B?style=flat&logo=slack&logoColor=white)
![CloudWatch Logs](https://img.shields.io/badge/CloudWatch_Logs-FF4F8B?style=flat&logo=amazon-cloudwatch&logoColor=white)
![CloudWatch Dashboards](https://img.shields.io/badge/CloudWatch_Dashboards-FF4F8B?style=flat&logo=amazon-cloudwatch&logoColor=white)

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

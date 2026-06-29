# Deploy OpenHands — AI Software Development Agent Deployment Guide

> **Document Type:** Huawei Cloud Solution Practice Deployment Guide
> **Document Version:** 01
> **Release Date:** 2026-06-26

---

## 1. Solution Overview

### 1.1 Application Scenarios

This solution deploys OpenHands on a Huawei Cloud Flexus X instance — an open-source AI software development generative agent platform. It can automatically complete coding, debugging, testing, and deployment tasks through natural language instructions.

Typical use cases include:

- **AI-Driven Development** — Describe requirements in natural language, and AI automatically completes the full development lifecycle
- **Automated Code Review** — Have AI review code and suggest improvements
- **Rapid Prototyping** — Quickly generate runnable prototype code from natural language descriptions
- **Multi-Model Collaboration** — Flexibly switch between Claude, GPT-4, DeepSeek, and other models

### 1.2 Solution Architecture

#### Single-Instance Deployment

Figure 1-1 Single-instance architecture diagram

This solution deploys the following resources:

- 1 x Huawei Cloud Flexus X instance, running the OpenHands Docker container
- 1 x Elastic IP (EIP) associated with the ECS, providing public Web UI access
- 1 x VPC with subnet for network isolation

#### Data Flow

1. Developer accesses OpenHands Web UI through a browser
2. OpenHands receives natural language instructions and calls the configured LLM for inference
3. Code/commands returned by the LLM are executed in a sandbox environment
4. Execution results are displayed in the Web UI for the developer

### 1.3 Solution Advantages

- **AI-Driven Development** — Describe requirements in natural language, AI automatically completes coding, debugging, and deployment
- **Web UI Access** — No local installation required, use the full development environment via browser
- **Multi-LLM Support** — Compatible with Claude, GPT-4, DeepSeek, and other mainstream models
- **Docker Containerization** — Isolated runtime environment with Docker-in-Docker support for Agent container calls
- **Active Open Source Community** — Continuous updates with rich plugin ecosystem

### 1.4 Constraints & Limitations

- Before deployment, you must have a Huawei Cloud account with completed real-name authentication and sufficient balance.
- If you select subscription billing, ensure sufficient account balance for automatic payment, or manually pay in "Billing Center > Pending Orders".
- Wait approximately 10 minutes after deployment for Docker image pull and container startup to complete.
- You need to configure an LLM API Key in the OpenHands Web UI before first use.
- OpenHands is accessed via browser; modern browsers are supported.

---

## 2. Cost Estimation

> This solution will deploy the resources listed below. Costs are estimates only and may differ from actual prices. See the Huawei Cloud Price Calculator for details.

### 2.1 Single-Instance Deployment

#### Table 2-1 Cost Estimation (Pay-Per-Use)

| Huawei Cloud Service | Configuration | Qty | Estimated Cost (1 hour) |
|-----------|---------|------|-----------------|
| Flexus X Instance | Billing: Pay-per-use<br>Region: cn-north-4<br>Flavor: x1.2u.4g<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 60GB | 1 | USD 0.05 |
| Elastic IP EIP | Billing: Pay-per-use<br>Line: Dynamic BGP<br>Bandwidth: Traffic-based<br>Size: 300Mbit/s | 1 | USD 0.00 |
| **Total** | — | — | **USD 0.05** |

> Estimated costs are for reference only. Actual costs depend on usage. See the official Huawei Cloud website for detailed pricing.

#### Table 2-2 Cost Estimation (Monthly Subscription)

| Huawei Cloud Service | Configuration | Qty | Estimated Cost (1 month) |
|-----------|---------|------|-----------------|
| Flexus X Instance | Billing: Monthly<br>Region: cn-north-4<br>Flavor: x1.2u.4g<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 60GB | 1 | USD 36.50 |
| Elastic IP EIP | Billing: Traffic-based<br>Line: Dynamic BGP<br>Bandwidth: 300Mbit/s | 1 | Traffic-based billing |
| **Total** | — | — | **USD 36.50 + EIP traffic fees** |

> LLM API token costs are billed separately by actual usage.

---

## 3. Implementation Steps

### 3.1 Preparation

#### 3.1.1 Obtain LLM API Key

OpenHands supports multiple LLM backends. Choose and obtain the corresponding API Key based on your needs:

**Option A: Claude API Key**
Step 1 Visit the [Anthropic Console](https://console.anthropic.com/).
Step 2 Navigate to "API Keys" and click "Create Key".
Step 3 Copy the generated API Key and store it securely.

**Option B: OpenAI API Key**
Step 1 Visit the [OpenAI Platform](https://platform.openai.com/api-keys).
Step 2 Click "Create new secret key".
Step 3 Copy the generated API Key and store it securely.

**Option C: DeepSeek API Key**
Step 1 Visit the [DeepSeek Open Platform](https://platform.deepseek.com/api_keys).
Step 2 Click "Create API Key".
Step 3 Copy the generated API Key and store it securely.

----End

#### 3.1.2 Create rf_admin_trust Agency (Optional)

Step 1 Open the Huawei Cloud console, hover over your account name, and open "Identity and Access Management".

Step 2 Navigate to "Agencies" and search for `rf_admin_trust`.

If the agency exists, skip the following creation steps.
If it does not exist, proceed with the steps below.

Step 3 Click "Create Agency", enter `rf_admin_trust` as the name, select "Cloud Service" as the agency type, enter `RFS`, and click "Done".

Step 4 Click "Authorize Now".

Step 5 Search for `Tenant Administrator`, select it, and click "Next".

Step 6 Select "All Resources" and click "Confirm" to complete configuration.

Step 7 Verify that `rf_admin_trust` appears in the agency list.

----End

### 3.2 Quick Deployment

> This section helps you deploy the OpenHands solution efficiently. Follow the steps below for one-click deployment.

Step 1 Click "Start Deployment" to navigate to the RFS deployment page.

Step 2 Click "Next", confirm the basic configuration, and set the ECS password.

**Table 3-1 Configuration Parameters**

| Parameter | Description | Default |
|------|------|--------|
| solution_name | Solution name, 4-24 chars, lowercase letters/digits/hyphens, must start with a lowercase letter | openhands |
| ecs_flavor | ECS instance flavor. x1.2u.4g (2vCPUs 4GiB) or above recommended. | x1.2u.4g |
| ecs_password | ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special characters | / |
| system_disk_size | System disk size (GB), range: 40-1024 | 60 |
| bandwidth_size | EIP bandwidth (Mbit/s), traffic billing, range: 1-300 | 300 |
| charging_mode | Billing mode: postPaid (pay-per-use) or prePaid (subscription) | postPaid |
| charging_unit | Subscription unit: month or year. Required when charging_mode is prePaid. | month |
| charging_period | Subscription period: 1-9 (month) or 1-3 (year). Required when charging_mode is prePaid. | 1 |

Step 3 Configure encryption and permissions as needed, then click "Next".

Step 4 Review the stack content. Optionally, click "Create Execution Plan" to preview estimated costs, then click "Deploy Stack Directly".

Step 5 Wait for `Apply required resource success`, then check the "Outputs" tab for connection information. Wait approximately 10 minutes before using the service (Docker image pull and startup take time).

> **Note:**
> - If your account balance is insufficient, go to "Billing Center > Top Up" to add funds.
> - If auto-payment fails for subscription billing, go to "Billing Center > Pending Orders" to pay manually.

----End

### 3.3 Getting Started

#### 3.3.1 Access OpenHands Web UI

Step 1 Open the Web UI address provided in the deployment output:

```
http://<EIP>:3000/
```

> **Note:** Replace `<EIP>` with the Elastic IP address from the RFS output.

Step 2 On first access, OpenHands will guide you through LLM configuration:

- Select an LLM provider (e.g., Anthropic, OpenAI, DeepSeek)
- Enter the corresponding API Key
- Select a model (e.g., claude-3-5-sonnet, gpt-4, deepseek-chat)

Step 3 After configuration, enter natural language instructions in the chat to have AI assist with development tasks.

Step 4 Verify OpenHands running status:

```bash
# SSH into ECS
ssh root@<EIP>

# Check container status
docker ps --filter name=openhands

# Check container logs
docker logs openhands --tail 50
```

----End

#### 3.3.2 Common Operations

**In the Web UI:**

- Enter natural language descriptions of requirements, e.g., "Create a Python Flask app with user registration and login"
- Upload files for AI to analyze or modify
- View each step of AI execution and output results
- Switch LLM providers and models in settings at any time

**Managing on ECS:**

```bash
# Restart OpenHands
docker compose -f /opt/openhands/docker-compose.yaml restart

# Stop OpenHands
docker compose -f /opt/openhands/docker-compose.yaml down

# Update to latest image
docker pull docker.openhands.dev/openhands/openhands:latest
docker compose -f /opt/openhands/docker-compose.yaml up -d
```

----End

### 3.4 Uninstall

Step 1 In the RFS console, find the stack created by this solution, then click the "Delete" button next to the stack name.

Step 2 In the confirmation dialog, select "Delete Resources", enter `Delete`, and click "Confirm" to uninstall the solution.

> **Note:** Uninstalling will release all resources (ECS, EIP, VPC, security group), but code and configurations saved in OpenHands will be lost when the ECS is deleted. Please back up important data in advance.

----End

---

## 4. Appendix

### 4.1 Glossary

| Term | Description |
|------|-------------|
| OpenHands | Open-source AI software development generative agent platform supporting automatic coding, debugging, and testing via natural language instructions |
| LLM | Large Language Model, such as Claude, GPT-4, DeepSeek, etc. |
| Docker | Containerization platform for packaging and running applications with their dependencies |
| Docker Compose | Multi-container Docker application orchestration tool |
| Flexus X | Huawei Cloud Flexus X instance for flexible, scalable compute |
| RFS | Resource Formation Service, Huawei Cloud's resource orchestration service |

### 4.2 References

- [OpenHands Official Documentation](https://docs.all-hands.dev/)
- [OpenHands GitHub](https://github.com/All-Hands-AI/OpenHands)
- [Huawei Cloud RFS](https://support.huaweicloud.com/rfs/)

---

## 5. Revision History

| Date | Revision |
|---------|---------|
| 2026-06-26 | First official release. |

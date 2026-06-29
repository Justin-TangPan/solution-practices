# Deploy AiToEarn — Deployment Guide

> **Document Type:** Huawei Cloud Solution Practice Deployment Guide
> **Document Version:** 01
> **Release Date:** 2026-06-26

---

## 1. Solution Overview

### 1.1 Application Scenarios

This solution deploys [AiToEarn](https://github.com/yikart/AiToEarn) on a Huawei Cloud Flexus X instance: an AI-powered content marketing platform that helps creators, brands, and enterprises create, distribute, engage, and monetize content across multiple social media platforms.

Typical use cases include:

- **Multi-Platform Publishing** — One-click publishing to TikTok, YouTube, Instagram, Facebook, Twitter/X, Pinterest, LinkedIn, and more
- **Engagement Automation** — Automated likes, bookmarks, follows, AI-powered comment replies
- **AI Content Creation** — AI video generation, image generation, batch matrix operations
- **Monetization Tasks** — CPS/CPE/CPM settlement models

### 1.2 Solution Architecture

#### Single-Instance Deployment

Figure 1-1 Single-instance architecture diagram

This solution deploys the following resources:

- 1 x Huawei Cloud Flexus X instance, running the AiToEarn application (Docker Compose orchestrates 12 containers)
- 1 x Elastic IP (EIP) associated with the ECS, providing public network access
- 1 x VPC with subnet for network isolation

#### Data Flow

1. User accesses the AiToEarn Web interface via browser
2. Nginx reverse proxy forwards requests to the aitoearn-web frontend container
3. aitoearn-server backend service handles business logic
4. MongoDB stores business data, Redis provides caching, RustFS provides object storage
5. aitoearn-ai container provides AI content generation capabilities

### 1.3 Solution Advantages

- **One-Click Deployment** — 12 containers auto-orchestrated, ready to use, deployment completes in ~10-15 minutes
- **Global Platform Coverage** — Supports 13+ major social media platforms worldwide
- **AI-Powered** — Built-in AI models for video/image generation, smart comments
- **Self-Hosted** — Data stays on your own server, fully private and controllable

### 1.4 Constraints & Limitations

- Before deployment, you must have a Huawei Cloud account with completed real-name authentication and sufficient balance.
- If you select subscription billing, ensure sufficient account balance for automatic payment, or manually pay in "Billing Center > Pending Orders".
- This solution requires 8vCPU 16GB+ ECS spec (12 containers are resource-intensive).
- Wait approximately 10-15 minutes after deployment for AiToEarn services to initialize.
- Social media OAuth credentials must be obtained and configured by the user.
- AI features require corresponding API keys to be configured.

---

## 2. Cost Estimation

> This solution will deploy the resources listed below. Costs are estimates only and may differ from actual prices. See the Huawei Cloud Price Calculator for details.

### 2.1 Single-Instance Deployment

#### Table 2-1 Cost Estimation (Pay-Per-Use)

| Huawei Cloud Service | Configuration | Qty | Estimated Cost (1 hour) |
|-----------|---------|------|-----------------|
| Flexus X Instance | Billing: Pay-per-use<br>Region: ap-southeast-3<br>Flavor: x1.8u.16g<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 100GB | 1 | USD 0.19 |
| Elastic IP EIP | Billing: Pay-per-use<br>Line: Dynamic BGP<br>Bandwidth: Traffic-based<br>Size: 300Mbit/s | 1 | USD 0.00 |
| **Total** | — | — | **USD 0.19** |

> Estimated costs are for reference only. Actual costs depend on usage. See the official Huawei Cloud website for detailed pricing.

#### Table 2-2 Cost Estimation (Monthly Subscription)

| Huawei Cloud Service | Configuration | Qty | Estimated Cost (1 month) |
|-----------|---------|------|-----------------|
| Flexus X Instance | Billing: Monthly<br>Region: ap-southeast-3<br>Flavor: x1.8u.16g<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 100GB | 1 | USD 140.00 |
| Elastic IP EIP | Billing: Pay-per-use<br>Line: Dynamic BGP<br>Bandwidth: Traffic-based<br>Size: 300Mbit/s | 1 | Traffic-based billing |
| **Total** | — | — | **USD 140.00 + EIP traffic fees** |

---

## 3. Implementation Steps

### 3.1 Preparation

#### 3.1.1 Create rf_admin_trust Agency (Optional)

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

> This section helps you deploy the "AiToEarn" solution efficiently. Follow the steps below for one-click deployment.

Step 1 Click "Start Deployment" to navigate to the RFS deployment page.

Step 2 Click "Next", confirm the basic configuration, and set the ECS password.

**Table 3-1 Configuration Parameters**

| Parameter | Description | Default |
|------|------|--------|
| solution_name | Solution name, 4-24 chars, lowercase letters/digits/hyphens, must start with a lowercase letter | aitoearn |
| ecs_flavor | ECS instance flavor. x1.8u.16g (8vCPUs 16GiB) recommended. | x1.8u.16g |
| ecs_password | ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special characters | / |
| system_disk_size | System disk size (GB), range: 40-1024 | 100 |
| bandwidth_size | EIP bandwidth (Mbit/s), traffic billing, range: 1-300 | 300 |
| charging_mode | Billing mode: postPaid (pay-per-use) or prePaid (subscription) | postPaid |
| charging_unit | Subscription unit: month or year. Required when charging_mode is prePaid. | month |
| charging_period | Subscription period: 1-9 (month) or 1-3 (year). Required when charging_mode is prePaid. | 1 |

Step 3 Configure encryption and permissions as needed, then click "Next".

Step 4 Review the stack content. Optionally, click "Create Execution Plan" to preview estimated costs, then click "Deploy Stack Directly".

Step 5 Wait for `Apply required resource success`, then check the "Outputs" tab for connection information. Wait approximately 10-15 minutes before using the service.

> **Note:**
> - If your account balance is insufficient, go to "Billing Center > Top Up" to add funds.
> - If auto-payment fails for subscription billing, go to "Billing Center > Pending Orders" to pay manually.

----End

### 3.3 Getting Started

#### 3.3.1 Access AiToEarn

Step 1 After deployment, access the Web URL from the RFS output in your browser.

```
http://<EIP>:8080
```

Step 2 Wait approximately 10-15 minutes for AiToEarn services to initialize.

Step 3 Confirm that the AiToEarn Web interface loads correctly.

----End

#### 3.3.2 Configure Social Media Accounts

Step 1 Log in to the AiToEarn admin dashboard.

Step 2 Go to "Account Management" and add the social media accounts you want to manage.

Step 3 Complete OAuth authorization for each platform as prompted.

> **Note:** OAuth credentials for each platform must be obtained by the user.

----End

#### 3.3.3 Configure AI Features (Optional)

To use AI content creation features, SSH into the ECS instance and configure the corresponding API Key in the `/opt/aitoearn/` directory.

```bash
ssh root@<EIP>
cd /opt/aitoearn/
# Configure AI API Key according to project documentation
```

----End

### 3.4 Uninstall

Step 1 In the RFS console, find the stack created by this solution, then click the "Delete" button next to the stack name.

Step 2 In the confirmation dialog, select "Delete Resources", enter `Delete`, and click "Confirm" to uninstall the solution.

----End

---

## 4. Appendix

### 4.1 Glossary

| Term | Description |
|------|-------------|
| AiToEarn | AI-powered content marketing platform supporting multi-platform publishing, engagement automation, and AI content creation |
| Flexus X | Huawei Cloud Flexus X instance for flexible, scalable compute |
| RFS | Resource Formation Service, Huawei Cloud's resource orchestration service |
| Docker Compose | Multi-container orchestration tool |
| MongoDB | NoSQL document database |
| Redis | In-memory cache database |
| RustFS | S3-compatible object storage service |

### 4.2 References

- [AiToEarn GitHub](https://github.com/yikart/AiToEarn)
- [AiToEarn Website](https://aitoearn.ai)
- [Huawei Cloud RFS](https://support.huaweicloud.com/rfs/)

---

## 5. Revision History

| Date | Revision |
|---------|---------|
| 2026-06-26 | First official release. |

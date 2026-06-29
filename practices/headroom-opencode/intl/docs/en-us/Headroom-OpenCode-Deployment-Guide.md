# Deploy Headroom + OpenCode — Deployment Guide

> **Document Type:** Huawei Cloud Solution Practice Deployment Guide
> **Document Version:** 01
> **Release Date:** 2026-06-26

---

## 1. Solution Overview

### 1.1 Application Scenarios

This solution deploys Headroom + OpenCode on a Huawei Cloud Flexus X instance: an open-source, low-cost, terminal-native AI coding environment.

Typical use cases include:

- **Daily AI-assisted Development**: Write, refactor, and debug code using natural language in the terminal. Headroom automatically compresses context to reduce token consumption.
- **Large Codebase Exploration**: Quickly read and understand unfamiliar codebases. AST-aware compression achieves up to 88% compression on file contents.
- **Log Analysis & Debugging**: Use AI to analyze large log files. Headroom achieves 90-95% compression rates on log content.
- **Architecture Design & Review**: Conduct system design discussions and code reviews in the terminal, with support for DeepSeek, Claude, and other models.

### 1.2 Solution Architecture

#### Single-Instance Deployment

Figure 1-1 Single-instance architecture diagram

This solution deploys the following resources:

- 1 x Huawei Flexus X ECS instance, hosting the Headroom proxy and OpenCode CLI
- 1 x Elastic IP (EIP) associated with the ECS, providing public network access
- 1 x VPC with subnet for network isolation

#### Data Flow

1. Developer types a prompt or command in OpenCode CLI
2. OpenCode sends the request to `http://localhost:8787` (Headroom proxy)
3. Headroom analyzes the context payload, compresses redundant data (tool outputs, file reads, conversation history)
4. Compressed request is forwarded to Huawei Cloud MaaS API
5. MaaS routes to the configured LLM for inference
6. Response flows back through Headroom to OpenCode
7. Developer sees the response in terminal

### 1.3 Solution Advantages

- **60-95% Token Compression**: Headroom's context compression engine dramatically reduces token consumption without sacrificing answer quality
- **Open Source, Zero License Fees**: Both OpenCode and Headroom are open-source projects with no vendor lock-in
- **Terminal-Native Workflow**: OpenCode runs directly in the terminal, integrating naturally into existing developer workflows
- **Multi-Model Support**: Switch between DeepSeek, Claude, and other models via simple configuration changes

### 1.4 Constraints & Limitations

- Before deployment, you must have a Huawei Cloud account with completed real-name authentication and sufficient balance.
- If you select subscription billing, ensure sufficient account balance for automatic payment, or manually pay in "Billing Center > Pending Orders".
- Wait approximately 10 minutes after deployment for Headroom proxy and OpenCode to initialize.
- You need to obtain an API Key from Huawei Cloud ModelArts MaaS before first use.

---

## 2. Cost Estimation

> This solution will deploy the resources listed below. Costs are estimates only and may differ from actual prices. See the Huawei Cloud Price Calculator for details.

### 2.1 Single-Instance Deployment

#### Table 2-1 Cost Estimation (Pay-Per-Use)

| Huawei Cloud Service | Configuration | Qty | Estimated Cost (1 hour) |
|-----------|---------|------|-----------------|
| Flexus X ECS | Billing: Pay-per-use<br>Region: ap-southeast-3<br>Flavor: x1.2u.4g<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 40GB | 1 | USD 0.14 |
| Elastic IP EIP | Billing: Pay-per-use<br>Line: Dynamic BGP<br>Bandwidth: Traffic-based<br>Size: 300Mbit/s | 1 | USD 0.00 |
| **Total** | — | — | **USD 0.14** |

> Estimated costs are for reference only. Actual costs depend on usage. See the official Huawei Cloud website for detailed pricing.

#### Table 2-2 Cost Estimation (Monthly Subscription)

| Huawei Cloud Service | Configuration | Qty | Estimated Cost (1 month) |
|-----------|---------|------|-----------------|
| Flexus X ECS | Billing: Monthly<br>Region: ap-southeast-3<br>Flavor: x1.2u.4g<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 40GB | 1 | USD 38.50 |
| Elastic IP EIP | Billing: Pay-per-use<br>Line: Dynamic BGP<br>Bandwidth: Traffic-based<br>Size: 300Mbit/s | 1 | Traffic-based billing |
| **Total** | — | — | **USD 38.50 + EIP traffic fees** |

---

## 3. Implementation Steps

### 3.1 Preparation

#### 3.1.1 Obtain MaaS API Key

Step 1 Log in to the Huawei Cloud console and navigate to "ModelArts ModelArts Studio".

Step 2 In the left navigation, select "MaaS > API Keys".

Step 3 Click "Create API Key", enter a name, then click "Confirm".

Step 4 Copy the generated API Key and store it securely. It will be needed when configuring Headroom.

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

> This section helps you deploy the "Headroom + OpenCode" solution efficiently. Follow the steps below for one-click deployment.

Step 1 Click "Start Deployment" to navigate to the RFS deployment page.

Step 2 Click "Next", confirm the basic configuration, and set the ECS password.

**Table 3-1 Configuration Parameters**

| Parameter | Description | Default |
|------|------|--------|
| solution_name | Solution name, 4-24 chars, lowercase letters/digits/hyphens, must start with a lowercase letter | headroom-opencode |
| ecs_flavor | ECS instance flavor | Recommended: x1.2u.4g |
| ecs_password | ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special characters | / |
| system_disk_size | System disk size (GB), range: 40-1024 | 40 |
| bandwidth_size | EIP bandwidth (Mbit/s), traffic billing, range: 1-300 | 300 |
| charging_mode | Billing mode: postPaid (pay-per-use) or prePaid (subscription) | postPaid |

Step 3 Configure encryption and permissions as needed, then click "Next".

Step 4 Review the stack content. Optionally, click "Create Execution Plan" to preview estimated costs, then click "Deploy Stack Directly".

Step 5 Wait for `Apply required resource success`, then check the "Outputs" tab for connection information. Wait approximately 10 minutes before using the service.

> **Note:**
> - If your account balance is insufficient, go to "Billing Center > Top Up" to add funds.
> - If auto-payment fails for subscription billing, go to "Billing Center > Pending Orders" to pay manually.

----End

### 3.3 Getting Started

#### 3.3.1 Configure API Key and Start OpenCode

Step 1 SSH into the deployed ECS instance (connection info is available in the RFS output).

Step 2 Set your MaaS API Key:

```bash
export ANTHROPIC_AUTH_TOKEN='your-maas-api-key'
source /root/.bashrc
```

> **Note:** Replace `your-maas-api-key` with the actual API Key obtained in step 3.1.1.

Step 3 Start OpenCode:

```bash
opencode
```

Step 4 Verify Headroom proxy status:

**Table 3-2 Headroom Management Endpoints**

| Endpoint | Description | Example |
|------|------|------|
| Health Check | Service health check | `curl http://localhost:8787/readyz` |
| Real-time Stats | Real-time statistics | `curl http://localhost:8787/stats` |
| Metrics | Prometheus metrics | `curl http://localhost:8787/metrics` |

Step 5 Start using OpenCode for AI-assisted programming. Headroom will automatically compress context to reduce token consumption.

----End

> **Note:** OpenCode automatically creates its configuration file at `/root/.config/opencode/opencode.json` on first launch, with `baseURL` pre-configured to point to the Headroom proxy address.

### 3.4 Uninstall

Step 1 In the RFS console, find the stack created by this solution, then click the "Delete" button next to the stack name.

Step 2 In the confirmation dialog, select "Delete Resources", enter `Delete`, and click "Confirm" to uninstall the solution.

----End

---

## 4. Appendix

### 4.1 Glossary

| Term | Description |
|------|------|
| OpenCode | Open-source terminal-native AI coding assistant supporting multiple LLM backends |
| Headroom | Open-source AI context compression proxy reducing token consumption by 60-95% |
| MaaS | ModelArts as a Service, Huawei Cloud's model-as-a-service platform |
| Flexus X | Huawei Cloud Flexus X instance for flexible, scalable compute |
| RFS | Resource Formation Service, Huawei Cloud's resource orchestration service |

### 4.2 References

- [OpenCode Documentation](https://opencode.ai)
- [Headroom GitHub Repository](https://github.com/chopratejas/headroom)
- [Huawei Cloud MaaS API Guide](https://support.huaweicloud.com/model-call-maas/model-call-060.html)
- [Huawei Cloud RFS](https://support.huaweicloud.com/rfs/)

---

## 5. Revision History

| Date | Revision |
|---------|---------|
| 2026-06-26 | First official release. |

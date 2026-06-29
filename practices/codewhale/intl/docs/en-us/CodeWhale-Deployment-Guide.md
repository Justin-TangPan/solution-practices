# Deploy CodeWhale — DeepSeek V4 AI Coding Agent Deployment Guide

> **Document Type:** Huawei Cloud Solution Practice Deployment Guide
> **Document Version:** 01
> **Release Date:** 2026-06-26

---

## 1. Solution Overview

### 1.1 Application Scenarios

This solution deploys CodeWhale on a Huawei Cloud Flexus X instance — a terminal-native AI coding agent for DeepSeek V4. Single binary, zero runtime dependencies, distributed via OBS with domestic acceleration, deployment completes in approximately 2 minutes.

Typical use cases include:

- **Daily AI-Assisted Programming** — Write, refactor, and debug code using natural language in the terminal. Supports Plan/Agent/YOLO three operation modes.
- **Large Codebase Exploration** — Quickly read and understand unfamiliar codebases, leveraging DeepSeek V4's million-token context capability.
- **Log Analysis & Debugging** — Use AI to analyze large log files and quickly locate root causes.
- **Automated Script Generation** — Generate Shell, Python, and other automation scripts from natural language descriptions.

### 1.2 Solution Architecture

#### Single-Instance Deployment

Figure 1-1 Single-instance architecture diagram

This solution deploys the following resources:

- 1 x Huawei Cloud Flexus X instance, running CodeWhale CLI and optional API Server
- 1 x Elastic IP (EIP) associated with the ECS, providing public SSH access
- 1 x VPC with subnet for network isolation

#### Data Flow

1. Developer types a prompt or command in the terminal
2. CodeWhale CLI sends the request directly to the DeepSeek API
3. DeepSeek V4 performs inference and returns the response
4. Developer sees the response in the terminal

(Optional) When API Server is started:
1. External clients access CodeWhale API Server via HTTP requests
2. API Server forwards requests to the DeepSeek API
3. Response is streamed back to the client via SSE

### 1.3 Solution Advantages

- **OBS Accelerated Distribution** — Pre-compiled binaries hosted on Huawei Cloud OBS for high-speed domestic download, with GitHub Release fallback
- **Zero-Dependency Installation** — Single Rust binary, no Docker/Node.js/Python runtime required
- **DeepSeek V4 Native Optimization** — Million-token context, prefix caching awareness, reasoning mode with streaming inference
- **Three Operation Modes** — Plan (read-only investigation) / Agent (interactive approval) / YOLO (auto-execution)
- **MIT Open Source License** — Active community, continuous updates, no vendor lock-in

### 1.4 Constraints & Limitations

- Before deployment, you must have a Huawei Cloud account with completed real-name authentication and sufficient balance.
- If you select subscription billing, ensure sufficient account balance for automatic payment, or manually pay in "Billing Center > Pending Orders".
- Wait approximately 2 minutes after deployment for CodeWhale to complete installation and initialization.
- You need to obtain an API Key from the DeepSeek platform before first use.
- CodeWhale is used via SSH terminal on the ECS instance, not a web interface.

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

> DeepSeek API token costs are billed separately by actual usage.

---

## 3. Implementation Steps

### 3.1 Preparation

#### 3.1.1 Obtain DeepSeek API Key

Step 1 Visit the [DeepSeek Open Platform](https://platform.deepseek.com/api_keys).

Step 2 After logging in, navigate to the "API Keys" page.

Step 3 Click "Create API Key", enter a name, then click "Create".

Step 4 Copy the generated API Key and store it securely. It will be needed when configuring CodeWhale.

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

> This section helps you deploy the CodeWhale solution efficiently. Follow the steps below for one-click deployment.

Step 1 Click "Start Deployment" to navigate to the RFS deployment page.

Step 2 Click "Next", confirm the basic configuration, and set the ECS password.

**Table 3-1 Configuration Parameters**

| Parameter | Description | Default |
|------|------|--------|
| solution_name | Solution name, 4-24 chars, lowercase letters/digits/hyphens, must start with a lowercase letter | codewhale |
| ecs_flavor | ECS instance flavor. x1.2u.4g (2vCPUs 4GiB) or above recommended. | x1.2u.4g |
| ecs_password | ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special characters | / |
| system_disk_size | System disk size (GB), range: 40-1024 | 60 |
| bandwidth_size | EIP bandwidth (Mbit/s), traffic billing, range: 1-300 | 300 |
| codewhale_version | CodeWhale version, supports latest and v0.8.47, etc. | latest |
| charging_mode | Billing mode: postPaid (pay-per-use) or prePaid (subscription) | postPaid |
| charging_unit | Subscription unit: month or year. Required when charging_mode is prePaid. | month |
| charging_period | Subscription period: 1-9 (month) or 1-3 (year). Required when charging_mode is prePaid. | 1 |

Step 3 Configure encryption and permissions as needed, then click "Next".

Step 4 Review the stack content. Optionally, click "Create Execution Plan" to preview estimated costs, then click "Deploy Stack Directly".

Step 5 Wait for `Apply required resource success`, then check the "Outputs" tab for connection information. Wait approximately 2 minutes before using the service.

> **Note:**
> - If your account balance is insufficient, go to "Billing Center > Top Up" to add funds.
> - If auto-payment fails for subscription billing, go to "Billing Center > Pending Orders" to pay manually.

----End

### 3.3 Getting Started

#### 3.3.1 Configure API Key and Start CodeWhale

Step 1 SSH into the deployed ECS instance (connection info is available in the RFS output).

Step 2 Set your DeepSeek API Key:

```bash
export DEEPSEEK_API_KEY='your-deepseek-api-key'
source /root/.bashrc
```

> **Note:** Replace `your-deepseek-api-key` with the actual API Key obtained in step 3.1.1.

Step 3 Configure authentication:

```bash
codewhale auth set --provider deepseek
```

Step 4 Start the CodeWhale interactive TUI:

```bash
codewhale
```

Step 5 Verify CodeWhale installation status:

```bash
codewhale --version
codewhale --help
```

Step 6 Start using CodeWhale for AI-assisted programming:

```bash
# Interactive TUI
codewhale

# One-shot task
codewhale "Write a Python script to analyze CSV data"

# Auto mode (no confirmation)
codewhale --yolo "Optimize this function"
```

----End

#### 3.3.2 Start API Server (Optional)

To run CodeWhale as a background API service:

```bash
export DEEPSEEK_API_KEY='your-deepseek-api-key'
systemctl enable --now codewhale
```

The API Server listens on the HTTP port by default. Check service status with `systemctl status codewhale`.

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
| CodeWhale | Terminal-native AI coding agent for DeepSeek V4, supporting interactive TUI and API Server modes |
| DeepSeek V4 | DeepSeek's fourth-generation large language model, supporting million-token context and streaming inference |
| Flexus X | Huawei Cloud Flexus X instance for flexible, scalable compute |
| RFS | Resource Formation Service, Huawei Cloud's resource orchestration service |
| TUI | Terminal User Interface, an interactive interface running in the terminal |
| OBS | Object Storage Service, Huawei Cloud's distributed storage service |

### 4.2 References

- [CodeWhale GitHub Repository](https://github.com/Hmbown/CodeWhale)
- [DeepSeek Open Platform](https://platform.deepseek.com/)
- [Huawei Cloud RFS](https://support.huaweicloud.com/rfs/)

---

## 5. Revision History

| Date | Revision |
|---------|---------|
| 2026-06-26 | First official release. |

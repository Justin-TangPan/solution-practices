# Deploy Supabase — Open Source Firebase Alternative Deployment Guide

> **Document Type:** Huawei Cloud Solution Practice Deployment Guide
> **Document Version:** 01
> **Release Date:** 2026-06-26

---

## 1. Solution Overview

### 1.1 Application Scenarios

This solution deploys Supabase on a Huawei Cloud Flexus X instance via Docker Compose — an open-source Firebase alternative (103k+ Stars on GitHub). It provides managed PostgreSQL database, user authentication, auto-generated REST/GraphQL APIs, real-time data subscriptions, file storage, and a complete backend service suite.

Typical use cases include:

- **Rapid Backend Setup** — Provide complete backend infrastructure (database + API + auth) for mobile/Web applications
- **AI Application Development** — Leverage the pgvector extension for building RAG and semantic search applications
- **Real-time Data Applications** — Subscribe to database changes via WebSocket in real time
- **Enterprise Internal Application Platform** — Self-hosted Backend-as-a-Service (BaaS) platform with full data sovereignty

### 1.2 Solution Architecture

#### Single-Instance Deployment

Figure 1-1 Single-instance architecture diagram

This solution deploys the following resources:

- 1 x Huawei Cloud Flexus X instance (8vCPUs 16GiB recommended), running approximately 10 Docker containers
- 1 x Elastic IP (EIP) associated with the ECS, providing public Dashboard and API access
- 1 x VPC with subnet for network isolation

#### Component Architecture

```
Kong (API Gateway) ← Unified entry point :8000
├── GoTrue (Authentication Service)
├── PostgREST (REST API)
├── Realtime (WebSocket real-time subscriptions)
├── Storage (File Storage)
├── imgproxy (Image Processing)
├── postgres-meta (Database Management API)
├── Studio (Web Management Panel)
└── PostgreSQL 15 + Supavisor (Connection Pool)
```

#### Data Flow

1. Developers/applications access Supabase services through the Kong API gateway (port 8000)
2. Authentication requests are handled by GoTrue, generating JWT Tokens
3. Data requests are automatically converted to PostgreSQL queries via PostgREST
4. Real-time subscriptions push database changes through WebSocket
5. File storage is persisted to local volumes through the Storage service

### 1.3 Solution Advantages

- **103k+ Stars Open Source Project** — Apache-2.0 license, active community, continuous updates
- **Docker Compose One-Click Deployment** — Approximately 10 containers auto-orchestrated, deployment completes in 10-15 minutes
- **SWR Image Acceleration** — Docker images pulled from Huawei Cloud SWR for stable and fast domestic access
- **Built-in PostgreSQL Extensions** — pgvector vector search, pgjwt authentication, PostGIS geospatial, and more
- **Complete Backend Capabilities** — Database + REST API + GraphQL + Auth + Real-time subscriptions + File storage + Dashboard
- **Auto-Retry Mechanism** — 5 retries to ensure image pull success rate

### 1.4 Constraints & Limitations

- Before deployment, you must have a Huawei Cloud account with completed real-name authentication and sufficient balance.
- If you select subscription billing, ensure sufficient account balance for automatic payment, or manually pay in "Billing Center > Pending Orders".
- Wait approximately 10-15 minutes after deployment for Docker image pull and container startup to complete.
- Recommended instance flavor is x1.8u.16g (8vCPUs 16GiB) or above to support approximately 10 containers running simultaneously.
- System disk is recommended to be 100GB or above for storing Docker images and database data.
- Please change the default JWT secret and database password immediately after first deployment.

---

## 2. Cost Estimation

> This solution will deploy the resources listed below. Costs are estimates only and may differ from actual prices. See the Huawei Cloud Price Calculator for details.

### 2.1 Single-Instance Deployment

#### Table 2-1 Cost Estimation (Pay-Per-Use)

| Huawei Cloud Service | Configuration | Qty | Estimated Cost (1 hour) |
|-----------|---------|------|-----------------|
| Flexus X Instance | Billing: Pay-per-use<br>Region: cn-north-4<br>Flavor: x1.8u.16g<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 100GB | 1 | USD 0.20 |
| Elastic IP EIP | Billing: Pay-per-use<br>Line: Dynamic BGP<br>Bandwidth: Traffic-based<br>Size: 300Mbit/s | 1 | USD 0.00 |
| **Total** | — | — | **USD 0.20** |

> Estimated costs are for reference only. Actual costs depend on usage. See the official Huawei Cloud website for detailed pricing.

#### Table 2-2 Cost Estimation (Monthly Subscription)

| Huawei Cloud Service | Configuration | Qty | Estimated Cost (1 month) |
|-----------|---------|------|-----------------|
| Flexus X Instance | Billing: Monthly<br>Region: cn-north-4<br>Flavor: x1.8u.16g<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 100GB | 1 | USD 146.00 |
| Elastic IP EIP | Billing: Traffic-based<br>Line: Dynamic BGP<br>Bandwidth: 300Mbit/s | 1 | Traffic-based billing |
| **Total** | — | — | **USD 146.00 + EIP traffic fees** |

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

> This section helps you deploy the Supabase solution efficiently. Follow the steps below for one-click deployment.

Step 1 Click "Start Deployment" to navigate to the RFS deployment page.

Step 2 Click "Next", confirm the basic configuration, and set the ECS password and database password.

**Table 3-1 Configuration Parameters**

| Parameter | Description | Default |
|------|------|--------|
| solution_name | Solution name, 4-24 chars, lowercase letters/digits/hyphens, must start with a lowercase letter | supabase |
| ecs_flavor | ECS instance flavor. x1.8u.16g (8vCPUs 16GiB) or above recommended. | x1.8u.16g |
| ecs_password | ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special characters | / |
| db_password | PostgreSQL database password, 8-26 chars, used as password for all database roles | / |
| system_disk_size | System disk size (GB), range: 40-1024, Supabase recommends 100GB or above | 100 |
| bandwidth_size | EIP bandwidth (Mbit/s), traffic billing, range: 1-300 | 300 |
| charging_mode | Billing mode: postPaid (pay-per-use) or prePaid (subscription) | postPaid |
| charging_unit | Subscription unit: month or year. Required when charging_mode is prePaid. | month |
| charging_period | Subscription period: 1-9 (month) or 1-3 (year). Required when charging_mode is prePaid. | 1 |

Step 3 Configure encryption and permissions as needed, then click "Next".

Step 4 Review the stack content. Optionally, click "Create Execution Plan" to preview estimated costs, then click "Deploy Stack Directly".

Step 5 Wait for `Apply required resource success`, then check the "Outputs" tab for connection information. Wait approximately 10-15 minutes before using the service (Docker image pull and startup take considerable time).

> **Note:**
> - If your account balance is insufficient, go to "Billing Center > Top Up" to add funds.
> - If auto-payment fails for subscription billing, go to "Billing Center > Pending Orders" to pay manually.

----End

### 3.3 Getting Started

#### 3.3.1 Access Supabase Dashboard

Step 1 Open the Dashboard address provided in the deployment output:

```
http://<EIP>:8000/project/default
```

> **Note:** Replace `<EIP>` with the Elastic IP address from the RFS output.

Step 2 On first access, the Supabase Studio management panel will load. You can use the panel to:

- View and manage database tables
- Configure user authentication (email, OAuth, phone, etc.)
- Manage file storage buckets
- View real-time subscription status
- Execute SQL queries

Step 3 Verify Supabase running status:

```bash
# SSH into ECS
ssh root@<EIP>

# Check container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check container logs
docker compose -f /opt/supabase/docker-compose.yaml logs --tail 50
```

----End

#### 3.3.2 Obtain API Keys

Supabase uses JWT for API authentication. Please check and securely store the following keys immediately after deployment:

```bash
# SSH in and view
ssh root@<EIP>
cat /opt/supabase/.env
```

**Table 3-2 API Keys**

| Key | Description | Usage |
|-----|------|------|
| `ANON_KEY` | Public access key (anonymous role) | Used by client applications with limited permissions |
| `SERVICE_ROLE_KEY` | Administrator key | Used by server-side with full permissions, **never expose to clients** |
| `POSTGRES_PASSWORD` | PostgreSQL database password | Used for database connections |

> **Security Note:** Please change the default `JWT_SECRET` and `POSTGRES_PASSWORD` immediately after deployment, and keep `SERVICE_ROLE_KEY` secure.

----End

#### 3.3.3 Change Security Keys (Recommended)

```bash
ssh root@<EIP>
vi /opt/supabase/.env
# Modify the following values:
# POSTGRES_PASSWORD=your-strong-password
# JWT_SECRET=your-random-secret (at least 32 characters)
# SECRET_KEY_BASE=your-random-secret

cd /opt/supabase && docker compose restart
```

----End

#### 3.3.4 Common Service Endpoints

**Table 3-3 Supabase Service Endpoints**

| Endpoint | Description | Example |
|------|------|------|
| Dashboard | Web management panel | `http://<EIP>:8000/project/default` |
| REST API | Auto-generated RESTful API | `http://<EIP>:8000/rest/v1/` |
| Auth API | User authentication API | `http://<EIP>:8000/auth/v1/` |
| Storage | File storage API | `http://<EIP>:8000/storage/v1/` |
| Realtime | WebSocket real-time subscriptions | `http://<EIP>:8000/realtime/v1/` |

----End

### 3.4 Uninstall

Step 1 In the RFS console, find the stack created by this solution, then click the "Delete" button next to the stack name.

Step 2 In the confirmation dialog, select "Delete Resources", enter `Delete`, and click "Confirm" to uninstall the solution.

> **Note:**
> - Uninstalling will release all resources (ECS, EIP, VPC, security group).
> - **Please back up database data in `/opt/supabase/volumes/db/data` before deleting**, as data will be unrecoverable after uninstallation.

----End

---

## 4. Appendix

### 4.1 Glossary

| Term | Description |
|------|-------------|
| Supabase | Open-source Firebase alternative providing PostgreSQL database, authentication, REST API, real-time subscriptions, file storage, and complete backend services |
| PostgreSQL | Open-source relational database, the core data storage engine of Supabase |
| Kong | Open-source API gateway serving as the unified entry point for Supabase |
| GoTrue | Open-source user authentication service supporting email, OAuth, phone, and more |
| PostgREST | Auto-generates RESTful APIs for PostgreSQL databases |
| pgvector | PostgreSQL vector search extension for AI and semantic search applications |
| Flexus X | Huawei Cloud Flexus X instance for flexible, scalable compute |
| RFS | Resource Formation Service, Huawei Cloud's resource orchestration service |
| SWR | SoftWare Repository for Container, Huawei Cloud's container image registry |
| JWT | JSON Web Token, a stateless token used for API authentication |

### 4.2 References

- [Supabase Official Documentation](https://supabase.com/docs)
- [Supabase GitHub](https://github.com/supabase/supabase)
- [Supabase Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting/docker)
- [Huawei Cloud RFS](https://support.huaweicloud.com/rfs/)

---

## 5. Revision History

| Date | Revision |
|---------|---------|
| 2026-06-26 | First official release. |

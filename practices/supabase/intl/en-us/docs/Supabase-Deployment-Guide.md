# Deploy Supabase — Open-Source Firebase Alternative Deployment Guide

> **Document Type:** Huawei Cloud Solution Practice Deployment Guide
> **Document Version:** 01
> **Release Date:** 2026-07-07

---

## 1. Solution Overview

### 1.1 Use Cases

This solution deploys Supabase — the open-source Firebase alternative (GitHub 103k+ Stars) — on a Huawei Cloud ECS instance via Docker Compose. It provides managed PostgreSQL database, user authentication, auto-generated REST/GraphQL APIs, real-time data subscriptions, file storage, and a complete Backend-as-a-Service (BaaS) capability.

Typical use cases:

- **Rapid backend setup** — Provide database + API + auth as a complete backend infrastructure for mobile/web apps
- **AI application development** — Leverage pgvector vector search extension for RAG and semantic search
- **Real-time data applications** — Subscribe to database changes via WebSocket in real time
- **Enterprise internal BaaS platform** — Self-hosted backend-as-a-service with full data sovereignty

### 1.2 Solution Architecture

#### Single-Instance Deployment

Figure 1-1 Single-instance deployment architecture

This solution deploys the following resources:

- 1 x Huawei Cloud ECS instance (recommended 8vCPUs 16GiB), running ~10 Docker containers
- 1 x Elastic Public IP (EIP) associated to ECS, providing public Dashboard and API access
- 1 x VPC and subnet for network isolation

#### Component Architecture

```
Kong (API Gateway) ← Unified entry point :8000
├── GoTrue (Authentication)
├── PostgREST (REST API)
├── Realtime (WebSocket real-time subscriptions)
├── Storage (File storage)
├── imgproxy (Image processing)
├── postgres-meta (Database management API)
├── Studio (Web management dashboard)
└── PostgreSQL 15 + Supavisor (Connection pooler)
```

#### Data Flow

1. Developers/apps access Supabase services through Kong API gateway (port 8000)
2. Auth requests are handled by GoTrue, generating JWT tokens
3. Data requests are automatically converted to PostgreSQL queries via PostgREST
4. Real-time subscriptions push database changes via WebSocket
5. File storage is persisted to local volumes via the Storage service

### 1.3 Key Benefits

- **103k+ Stars open-source project** — Apache-2.0 license, active community, continuous updates
- **Docker Compose one-click deployment** — ~10 containers auto-orchestrated, 10-15 minutes to complete
- **Official Docker Hub images** — No mirror dependency, stable pulls from official registry
- **Built-in PostgreSQL extensions** — pgvector vector search, pgjwt auth, PostGIS geospatial, etc.
- **Complete backend capability** — Database + REST API + GraphQL + Auth + Real-time + Storage + Dashboard
- **Auto-retry mechanism** — 5 retries ensure image pull success rate

### 1.4 Constraints and Limitations

- A Huawei Cloud account with real-name authentication and sufficient balance is required before deployment.
- For subscription billing, ensure sufficient balance for auto-deduction, or manually pay at "Billing Center > Unpaid Orders".
- Wait ~10-15 minutes after deployment for Docker image pulls and container startup to complete.
- Recommended ECS flavor is c7n.2xlarge.2 (8vCPUs 16GiB) or above to support ~10 containers running simultaneously.
- System disk should be at least 100GB for Docker images and database data.
- Modify the default JWT secret and database password immediately after first deployment.

---

## 2. Resource and Cost Planning

> This solution deploys the following resources. Costs are estimates only; actual costs may vary.

### 2.1 Single-Instance Deployment

#### Table 2-1 Cost Estimate (Pay-per-use)

| Huawei Cloud Service | Configuration | Quantity | Estimated Cost (1 hour) |
|---------------------|---------------|----------|------------------------|
| ECS Instance | Billing: Pay-per-use<br>Region: China-Hong Kong (ap-southeast-1)<br>Flavor: c7n.2xlarge.2<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 100GB | 1 | ~$0.20 |
| Elastic Public IP EIP | Billing: Pay-per-use<br>Line: Dynamic BGP<br>Bandwidth: Traffic billing<br>Size: 300Mbit/s | 1 | $0.00 |
| **Total** | — | — | **~$0.20** |

> Estimated costs are for reference only. Actual costs depend on usage. See Huawei Cloud pricing for details.

#### Table 2-2 Cost Estimate (Subscription)

| Huawei Cloud Service | Configuration | Quantity | Estimated Cost (1 month) |
|---------------------|---------------|----------|-------------------------|
| ECS Instance | Billing: Subscription<br>Region: China-Hong Kong (ap-southeast-1)<br>Flavor: c7n.2xlarge.2<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 100GB | 1 | ~$146.00 |
| Elastic Public IP EIP | Billing: Traffic<br>Line: Dynamic BGP<br>Bandwidth: 300Mbit/s | 1 | Billed by actual traffic |
| **Total** | — | — | **~$146.00/month + EIP traffic** |

---

## 3. Implementation Steps

### 3.1 Prerequisites

#### 3.1.1 Create rf_admin_trust Delegation (Optional)

Step 1 Open the Huawei Cloud console, hover over the username in the upper right, and open "Unified Identity Authentication".

Step 2 Navigate to the "Agencies" page and search for `rf_admin_trust`.

If the delegation already exists, skip the following creation steps. If not, proceed as follows.

Step 3 Click "Create Agency", enter `rf_admin_trust` as the name, select "Cloud Service" as the type, select `RFS` as the cloud service, and click "OK".

Step 4 Click "Authorize Now".

Step 5 Search for and select `Tenant Administrator`, then click "Next".

Step 6 Select "All Resources" for the authorization scope, and click "OK".

Step 7 Confirm that `rf_admin_trust` appears in the agency list.

----End

### 3.2 Quick Deployment

> This section helps you efficiently deploy the Supabase solution. Follow these steps for one-click deployment.

Step 1 Click "Start Deployment" to navigate to the RFS console.

Step 2 Click "Next", confirm the basic configuration, and set the ECS password and database password.

**Table 3-1 Configuration Parameters**

| Parameter | Description | Default |
|-----------|-------------|---------|
| solution_name | Solution name, 4-24 chars, lowercase letters/digits/hyphens, must start with a lowercase letter | supabase |
| ecs_flavor | ECS flavor, c7n.2xlarge.2 (8vCPUs 16GiB) or above recommended. Change to match available flavors in target region | c7n.2xlarge.2 |
| ecs_password | ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special characters | / |
| db_password | PostgreSQL password, 8-26 chars, used as the password for all database roles | / |
| system_disk_size | System disk size (GB), high-IO type, range: 40-1024, 100GB recommended for Supabase | 100 |
| bandwidth_size | EIP bandwidth (Mbit/s), traffic billing, range: 1-300 | 300 |
| charging_mode | Billing mode: postPaid (pay-per-use) or prePaid (subscription) | postPaid |
| charging_unit | Subscription unit: month or year, only effective for prePaid | month |
| charging_period | Subscription period, 1-9 (month) or 1-3 (year), only effective for prePaid | 1 |

Step 3 Configure encryption and permissions as needed, then click "Next".

Step 4 Review the stack content. Optionally click "Create Execution Plan" to preview estimated costs, then click "Deploy Stack Directly".

Step 5 Wait for `Apply required resource success`, then check the "Outputs" tab for connection information. Wait ~10-15 minutes before using the services (Docker image pulls and container startup take time).

> **Note:**
> - If account balance is insufficient, go to "Billing Center > Top Up" to recharge.
> - If subscription auto-deduction fails, go to "Billing Center > Unpaid Orders" to pay manually.

----End

### 3.3 Getting Started

#### 3.3.1 Access the Supabase Dashboard

Step 1 Open the Dashboard URL from the deployment output in your browser:

```
http://<EIP>:8000/project/default
```

> **Note:** Replace `<EIP>` with the elastic public IP address from the RFS output.

Step 2 On first access, the Supabase Studio management dashboard will load. You can:

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

#### 3.3.2 Get API Keys

Supabase uses JWT for API authentication. View and safeguard the following keys after deployment:

```bash
# SSH in and view
ssh root@<EIP>
cat /opt/supabase/.env
```

**Table 3-2 API Keys**

| Key | Description | Usage |
|-----|-------------|-------|
| `ANON_KEY` | Public access key (anonymous role) | Client-side apps, restricted permissions |
| `SERVICE_ROLE_KEY` | Admin key | Server-side use, full permissions, **never expose to client** |
| `POSTGRES_PASSWORD` | PostgreSQL database password | Database connections |

> **Security Note:** `JWT_SECRET` and `SECRET_KEY_BASE` are randomly generated during deployment. `ANON_KEY`/`SERVICE_ROLE_KEY` are derived and signed from `JWT_SECRET`. Safeguard all keys in `.env` — never expose `SERVICE_ROLE_KEY` to the client.

----End

#### 3.3.3 Rotate Security Keys (If Needed)

`JWT_SECRET`, `SECRET_KEY_BASE` are randomly generated during deployment. `ANON_KEY`/`SERVICE_ROLE_KEY` are signed from `JWT_SECRET`. To rotate:

```bash
ssh root@<EIP>
cd /opt/supabase

# 1. Generate new JWT_SECRET
NEW_JWT=$(openssl rand -base64 32)

# 2. Re-sign ANON_KEY / SERVICE_ROLE_KEY with new JWT_SECRET
gen_jwt() {
  local secret="$1" role="$2"
  local h p sig
  h=$(printf '%s' '{"alg":"HS256","typ":"JWT"}' | openssl base64 -A | tr '/+' '_-' | tr -d '=')
  p=$(printf '%s' "{\"iss\":\"supabase\",\"role\":\"$role\",\"exp\":1983810273,\"ref\":\"default\"}" | openssl base64 -A | tr '/+' '_-' | tr -d '=')
  sig=$(printf '%s' "$h.$p" | openssl dgst -sha256 -hmac "$secret" -binary | openssl base64 -A | tr '/+' '_-' | tr -d '=')
  printf '%s' "$h.$p.$sig"
}

# 3. Write back to .env and restart
sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$NEW_JWT|" .env
sed -i "s|^ANON_KEY=.*|ANON_KEY=$(gen_jwt "$NEW_JWT" anon)|" .env
sed -i "s|^SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=$(gen_jwt "$NEW_JWT" service_role)|" .env
docker compose restart
```

> **Note:** Changing `JWT_SECRET` without re-signing `ANON_KEY`/`SERVICE_ROLE_KEY` will cause REST/Auth/Storage signature verification to fail. `POSTGRES_PASSWORD` rotation requires `ALTER USER` for all database roles — recommend rebuilding the stack instead.

----End

#### 3.3.4 Common Service Endpoints

**Table 3-3 Supabase Service Endpoints**

| Endpoint | Description | Example |
|----------|-------------|---------|
| Dashboard | Web management dashboard | `http://<EIP>:8000/project/default` |
| REST API | Auto-generated RESTful API | `http://<EIP>:8000/rest/v1/` |
| Auth API | User authentication API | `http://<EIP>:8000/auth/v1/` |
| Storage | File storage API | `http://<EIP>:8000/storage/v1/` |
| Realtime | WebSocket real-time subscriptions | `http://<EIP>:8000/realtime/v1/` |

----End

### 3.4 Uninstall

Step 1 In the RFS console, find the stack created by this solution, and click "Delete" next to the stack name.

Step 2 In the confirmation dialog, select "Delete Resources", enter `Delete`, and click "OK".

> **Note:**
> - Uninstalling releases all resources (ECS, EIP, VPC, security group).
> - **Back up `/opt/supabase/volumes/db/data` before deletion** — data is unrecoverable after uninstall.

----End

---

## 4. Appendix

### 4.1 Glossary

| Term | Description |
|------|-------------|
| Supabase | Open-source Firebase alternative providing PostgreSQL, auth, REST API, real-time subscriptions, file storage, etc. |
| PostgreSQL | Open-source relational database, Supabase's core data storage engine |
| Kong | Open-source API gateway, serves as Supabase's unified entry point |
| GoTrue | Open-source user authentication service supporting email, OAuth, phone, etc. |
| PostgREST | Auto-generates RESTful API from PostgreSQL database schema |
| pgvector | PostgreSQL vector search extension for AI and semantic search |
| RFS | Resource Formation Service, Huawei Cloud's infrastructure-as-code service |
| JWT | JSON Web Token, stateless token for API authentication |

### 4.2 Reference Links

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase GitHub](https://github.com/supabase/supabase)
- [Supabase Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting/docker)
- [Huawei Cloud RFS](https://support.huaweicloud.com/intl/en-us/rfs/)

---

## 5. Revision History

| Date | Revision |
|------|----------|
| 2026-07-07 | Initial release for intl ap-southeast-1 (Hong Kong). |

# Quickly Deploy LiteLLM — International Deployment Guide

> **Document type:** Huawei Cloud Solution Practice Deployment Guide
> **Document version:** 01
> **Release date:** 2026-07-10
> **Site:** intl (International)
> **Deployment:** RFS one-click deployment · Standard / High Availability

This guide covers both the LiteLLM standard and high-availability (HA) editions. The standard edition is intended for development, validation, and small or medium shared gateways. The HA edition is intended for production scenarios that need multiple replicas, managed database and cache services, and an HTTPS endpoint.

> **Candidate status:** The HA `deploying-litellm_v1.tf` is a candidate template that has not completed deployment validation on real Huawei Cloud resources. This guide describes its current implementation; it does not claim that the template has passed cloud testing or has been formally released. Before deployment, validate quotas, flavors, availability zones, and provider compatibility in a non-production account in the target region.

---

## 1. Solution Overview

### 1.1 Use Cases

LiteLLM provides a unified, OpenAI-compatible proxy for connecting multiple model providers through one gateway. This practice deploys cloud resources and LiteLLM through an RFS template for:

- **Development and integration validation:** The standard edition runs LiteLLM, PostgreSQL, and Prometheus on one ECS.
- **Shared enterprise model gateway:** The HA edition uses three CCE nodes and four LiteLLM replicas by default, with RDS for PostgreSQL 16 primary/standby and DCS Redis 7.0 HA.
- **Centralized authentication and usage management:** LiteLLM master keys, virtual keys, and database persistence provide centralized model access and usage records.

### 1.2 Architecture

#### 1.2.1 Standard Edition

```text
Internet
   │
   └── EIP ── ECS / Ubuntu 24.04
                 └── Docker Compose
                     ├── LiteLLM Proxy :4000
                     ├── PostgreSQL 16
                     └── Prometheus :9090
```

The standard template creates one VPC, subnet, security group, traffic-billed EIP, and ECS. TCP/4000 and TCP/9090 are publicly accessible. SSH is restricted to the template's Cloud Shell address, `121.36.59.153/32`.

#### 1.2.2 High-Availability Edition

```text
Internet
   │ HTTPS/443
   ▼
ELB (two availability zones)
   │
CCE Turbo (multi-AZ, three nodes by default)
   └── LiteLLM Proxy × 4
       ├── RDS for PostgreSQL 16 (primary/standby)
       ├── DCS Redis 7.0 (HA)
       └── NAT gateway → model provider APIs
```

The HA template creates:

- One VPC, four subnets (public, private, and two ENI subnets), and one security group that allows only VPC-internal access;
- Three EIPs for the public ELB endpoint, CCE cluster access, and NAT SNAT;
- One ELB spanning at least two availability zones, with a mandatory HTTPS/443 public endpoint;
- One multi-AZ CCE Turbo v1.34 cluster whose node pool targets three nodes by default and allows up to ten;
- One LiteLLM Kubernetes Deployment with four fixed replicas, each requesting and limiting 1 vCPU and 4 GiB memory;
- One RDS for PostgreSQL 16 primary/standby instance, 8 vCPU/16 GiB and 100 GB CLOUDSSD by default;
- One DCS Redis 7.0 HA instance, 8 GB by default, with automatic backup enabled;
- One NAT gateway and three SNAT rules for private node and pod-network access to external model services.

### 1.3 Key Advantages

- **Two scales in one delivery:** Choose one ECS for standard deployment or three CCE nodes and four replicas by default for HA.
- **Managed state services:** HA uses RDS PostgreSQL 16 primary/standby and DCS Redis 7.0 HA.
- **Encrypted ingress:** HA exposes only ELB HTTPS/443 and requires an existing server certificate and its covered domain.
- **Consistent regional delivery:** English and Chinese templates cover eight International regions explicitly through their directories and provider configuration.

### 1.4 Constraints

- The Huawei Cloud account must be active, funded, and authorized to create and delete all resources. IAM users should use an RFS agency with sufficient least-privilege permissions.
- HA requires at least two available category-0 L7 ELB availability zones. The selected RDS and DCS HA flavors must each support at least two distinct availability zones.
- Create or import an ELB server certificate in the deployment region first. After deployment, point an A record for the certificate-covered domain to the ELB EIP output.
- Generate `litellm_master_key` and `litellm_salt_key` with a cryptographically secure random generator. Never change the Salt Key after encrypted data has been stored, and never put secrets in documentation, tickets, or logs.
- HA pins `docker.litellm.ai/berriai/litellm:1.87.0`; standard currently uses `ghcr.io/berriai/litellm:main-stable`. Assess their upgrade and version-drift risks separately.
- The HA candidate has not been cloud-tested. Before production, complete Terraform syntax checks, an RFS execution plan, real deployment, health checks, HTTPS access validation, and uninstall validation.

---

## 2. Resources and Cost Planning

Prices vary by region, flavor, promotion, and billing rules. The tables identify billable resources without inventing unverified amounts. Check the RFS execution plan and Huawei Cloud pricing calculator; the actual bill prevails.

### 2.1 Standard Edition

#### Table 2-1 Pay-per-use resources

| Huawei Cloud service | Current template configuration | Quantity | Cost rule |
|---|---|---:|---|
| VPC / subnet / security group | `172.16.0.0/16`; subnet `172.16.1.0/24` | 1 each | Follow console billing rules |
| ECS | Ubuntu 24.04; `c7n.2xlarge.2`; 200 GB SSD; `postPaid` | 1 | Check target-region on-demand price |
| EIP / bandwidth | Dynamic BGP; 200 Mbit/s by default; traffic billing | 1 | Based on actual traffic |
| LiteLLM / PostgreSQL / Prometheus | Docker Compose containers on ECS | 1 each | Open-source software is not a separate cloud-resource charge |

#### Table 2-2 Subscription resources

| Huawei Cloud service | Current template configuration | Quantity | Cost rule |
|---|---|---:|---|
| VPC / subnet / security group | Same as pay-per-use | 1 each | Follow console billing rules |
| ECS | `charging_mode=prePaid`; month/year period | 1 | Check target-region subscription price |
| EIP / bandwidth | Remains `postPaid` and traffic-billed | 1 | Calculate separately from ECS subscription |
| System disk | 200 GB SSD by default, attached to ECS | 1 | Follow the resource-stack plan |

### 2.2 High-Availability Edition

#### Table 2-3 Pay-per-use resources

| Huawei Cloud service | Current template configuration | Quantity | Cost rule |
|---|---|---:|---|
| VPC / subnets / security group | One VPC, four subnets, one security group | 1 set | Follow console billing rules |
| EIP / bandwidth | 300 Mbit/s by default, traffic billing | 3 | Based on actual traffic |
| ELB | L7 performance flavor result; two AZs; HTTPS/443 | 1 | Check target-region on-demand price |
| CCE Turbo | v1.34, multi-AZ; `cce.s2.small` by default | 1 | Check cluster-management charges |
| CCE node pool | `c7n.2xlarge.2`; 100 GB GPSSD; target 3 nodes | 1 pool / 3 nodes | Check ECS node and EVS prices |
| RDS for PostgreSQL | PostgreSQL 16 primary/standby; 8 vCPU/16 GiB; 100 GB | 1 | Check RDS on-demand price |
| DCS Redis | Redis 7.0 HA; 8 GB by default | 1 | Check DCS on-demand price |
| NAT gateway | Small; three SNAT rules share the third EIP | 1 | Check NAT and traffic charges |

#### Table 2-4 Subscription resources

| Huawei Cloud service | Current template configuration | Quantity | Cost rule |
|---|---|---:|---|
| ELB | `prePaid`, month/year period, HTTPS/443 | 1 | Check target-region subscription price |
| CCE Turbo and node pool | One cluster; target three nodes | 1 set | Calculate cluster, ECS nodes, and disks separately |
| RDS for PostgreSQL | PostgreSQL 16 primary/standby; 100 GB | 1 | Check RDS subscription price |
| DCS Redis | Redis 7.0 HA; 8 GB by default | 1 | Check DCS subscription price |
| NAT gateway | Small | 1 | Check NAT subscription price |
| EIP / traffic | Three traffic-billed EIPs | 3 | Calculate separately from subscriptions |

> **Cost disclaimer:** Estimates are for planning only. Actual cost depends on the region, flavors, purchase period, network traffic, and promotions. The actual Huawei Cloud bill prevails.

---

## 3. Deployment Steps

### 3.1 Preparation

#### 3.1.1 Check account, quotas, and regional capabilities

1. Sign in to the [Huawei Cloud International console](https://console-intl.huaweicloud.com/).
2. Confirm account status and VPC, EIP, ELB, CCE, ECS, RDS, DCS, and NAT gateway quotas.
3. In the target region, check availability of `c7n.2xlarge.2`, `rds.pg.x1.2xlarge.2.ha`, a DCS Redis 7.0 HA flavor, and at least two AZs. If a default flavor is unavailable, change only the corresponding configurable flavor; do not bypass the HA AZ precondition.
4. IAM users should create or select a sufficiently authorized agency according to the [RFS agency documentation](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0017.html). Apply least privilege and do not store AK/SK credentials in documents or templates.

#### 3.1.2 Prepare the HA certificate and domain

1. Prepare a manageable DNS domain and a valid server certificate covering the intended hostname.
2. Add the server certificate in the target region's ELB console and record its ID. Import it separately in every deployment region.
3. The ID must contain 32-36 hexadecimal characters or hyphens; enter it as `elb_certificate_id`.
4. After the stack outputs the ELB EIP, create the A record. Do not point DNS at an unknown address before deployment.

#### 3.1.3 Generate HA LiteLLM keys

Run this in a secure terminal and store the results in an approved password manager:

```bash
MASTER_KEY="sk-$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9_-' | head -c 45)"
SALT_KEY="$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9_-' | head -c 48)"
printf 'master length=%s\nsalt length=%s\n' "${#MASTER_KEY}" "${#SALT_KEY}"
```

`MASTER_KEY` must be 32-64 characters in total and begin with `sk-`; `SALT_KEY` must be 32-64 characters. Both allow only letters, digits, underscores, and hyphens.

### 3.2 Quick Deployment

#### 3.2.1 Availability

| Deployment | Site | Regions |
|---|---|---|
| RFS one-click · Standard | intl | The eight regions below |
| RFS one-click · HA candidate | intl | The eight regions below; cloud testing is required per region |

| Region | Name | Standard template | HA candidate template |
|---|---|---|---|
| `ap-southeast-1` | CN-Hong Kong | `litellm-standard-en-ap-southeast-1.tf` | `deploying-litellm_v1.tf` |
| `ap-southeast-2` | AP-Bangkok | `litellm-standard-en-ap-southeast-2.tf` | `deploying-litellm_v1.tf` |
| `ap-southeast-3` | AP-Singapore | `litellm-standard-en-ap-southeast-3.tf` | `deploying-litellm_v1.tf` |
| `af-south-1` | AF-Johannesburg | `litellm-standard-en-af-south-1.tf` | `deploying-litellm_v1.tf` |
| `af-north-1` | AF-Cairo | `litellm-standard-en-af-north-1.tf` | `deploying-litellm_v1.tf` |
| `tr-west-1` | TR-Istanbul | `litellm-standard-en-tr-west-1.tf` | `deploying-litellm_v1.tf` |
| `la-north-2` | LA-Mexico City2 | `litellm-standard-en-la-north-2.tf` | `deploying-litellm_v1.tf` |
| `sa-brazil-1` | LA-São Paulo1 | `litellm-standard-en-sa-brazil-1.tf` | `deploying-litellm_v1.tf` |

> The repository does not provide published production OBS template URLs, so this guide does not invent one-click deep links. Select the target region in the [RFS console](https://console-intl.huaweicloud.com/rf/) and upload the corresponding local template. Keep the `_v1` candidate name until real-cloud validation is complete.

#### 3.2.2 Standard parameters

The standard edition has 11 variables:

| Parameter | Default | Description |
|---|---|---|
| `solution_name` | `litellm-llm-gateway` | 4-24 characters; starts lowercase; lowercase letters, digits, hyphens |
| `ecs_flavor` | `c7n.2xlarge.2` | ECS flavor; adjust to a flavor sold in the region |
| `ecs_password` | Required | ECS root password, 8-26 characters, at least three of four character classes |
| `db_password` | Required | Internal PostgreSQL password, 8-26 characters |
| `master_key` | Required | LiteLLM admin/API master key; must begin with `sk-` |
| `salt_key` | Empty | Encryption Salt Key; generated by bootstrap when empty and must not later change |
| `system_disk_size` | `200` | SSD system disk, 40-1024 GB |
| `bandwidth_size` | `200` | EIP bandwidth, 1-300 Mbit/s, traffic billing |
| `charging_mode` | `postPaid` | `postPaid` pay-per-use or `prePaid` subscription |
| `charging_unit` | `month` | `month` or `year`; effective only for `prePaid` |
| `charging_period` | `1` | 1-9 months or 1-3 years; effective only for `prePaid` |

#### 3.2.3 High-availability parameters

The HA edition has 17 variables:

| Parameter | Default | Description |
|---|---|---|
| `resource_name_prefix` | `ha-litellm` | 4-24 characters; starts lowercase; lowercase letters, digits, hyphens |
| `bandwidth_size` | `300` | Bandwidth for three EIPs, 1-300 Mbit/s, traffic billing |
| `elb_certificate_id` | Required | Existing ELB server certificate ID for HTTPS/443 |
| `litellm_version` | `1.87.0` | Fixed; image `docker.litellm.ai/berriai/litellm:1.87.0` |
| `litellm_master_key` | Required | CSPRNG value beginning `sk-`, 32-64 total characters |
| `litellm_salt_key` | Required | CSPRNG value, 32-64 characters; never change after data is stored |
| `cce_cluster_flavor` | `cce.s2.small` | `cce.s2.small/medium/large/xlarge` |
| `cce_node_pool_password` | Required | 8-24 characters with uppercase, lowercase, and a digit or allowed special character |
| `cce_node_pool_flavor` | `c7n.2xlarge.2` | CCE node ECS flavor; default meets the recommended 4 vCPU/8 GiB per instance |
| `cce_node_pool_count` | `3` | Target node count 1-9; pool maximum is 10 |
| `rds_flavor` | `rds.pg.x1.2xlarge.2.ha` | RDS PostgreSQL primary/standby; 8 vCPU/16 GiB by default |
| `pgsql_admin_password` | Required | PostgreSQL administrator password, 8-24 characters |
| `redis_capacity` | `8` | GB; one of 1, 2, 4, 8, 16, 32, 64 |
| `redis_password` | Required | Redis password, 8-24 characters |
| `charging_mode` | `postPaid` | `postPaid` pay-per-use or `prePaid` subscription |
| `charging_unit` | `month` | `month` or `year`; effective only for `prePaid` |
| `charging_period` | `1` | 1-9 months or 1-3 years; effective only for `prePaid` |

#### 3.2.4 Create and deploy the stack

1. Open the [RFS console](https://console-intl.huaweicloud.com/rf/) and switch to a region in the availability table.
2. Create a stack and upload the matching region, language, and deployment-edition Terraform file. Never upload a template for another region.
3. Complete every required parameter. For HA, provide the certificate ID, both LiteLLM keys, and CCE, RDS, and Redis passwords.
4. Attach a sufficiently authorized RFS agency, create an execution plan, and inspect resources, flavors, and costs.
5. Deploy and wait for the stack to succeed. Run the first HA candidate deployment in a non-production environment and retain complete validation evidence.
6. Read `access_info` for standard; read `instructions` and record the ELB EIP for HA.

### 3.3 Getting Started

#### 3.3.1 Validate the standard edition

1. Open the Admin UI URL from `access_info`; standard uses HTTP and EIP TCP/4000.
2. Sign in with `master_key`, then add models and provider API keys.
3. Verify the output health URL and `/health/liveliness`.
4. Access Prometheus on EIP TCP/9090 if required. Before production, restrict security-group sources for 4000/9090 and add a TLS reverse proxy.

#### 3.3.2 Configure DNS and validate HA HTTPS

1. Copy the ELB EIP from the RFS `instructions` output.
2. Create an A record for the certificate-covered hostname pointing to this EIP. See [Huawei Cloud DNS A record rules](https://support.huaweicloud.com/intl/en-us/usermanual-dns/dns_usermanual_0601.html).
3. After propagation, use only HTTPS/443 with that hostname. Direct EIP access fails certificate hostname validation.
4. Set `LITELLM_BASE_URL` to the actual HTTPS hostname and run:

```bash
curl --fail --show-error "${LITELLM_BASE_URL}/health/liveliness"
curl --fail --show-error "${LITELLM_BASE_URL}/health/readiness"
```

5. Sign in with `litellm_master_key` and add models. Call `/v1/chat/completions` with the master key or a virtual key as the Bearer token.
6. Confirm that the `litellm-proxy` Deployment has four Ready replicas and review cross-host/cross-AZ placement. Validate RDS, DCS, ELB, NAT, and every health probe.

#### 3.3.3 Security checks

- Never store real keys or passwords in chat, screenshots, Markdown, Terraform defaults, or logs.
- Standard exposes ports 4000 and 9090 publicly; restrict source CIDRs and add HTTPS before production.
- HA exposes HTTPS/443 only; application port 4000 remains behind a cluster-internal ClusterIP.
- Assess connection and data impact before rotating the master key, database password, or Redis password. Never rotate the Salt Key after encrypted data exists.
- Monitor certificate expiry and update the ELB binding before expiration.

### 3.4 Troubleshooting

| Symptom | Check | Recommended action |
|---|---|---|
| Invalid subscription period in RFS plan | `charging_unit`, `charging_period` | Use 1-9 for months or 1-3 for years |
| HA precondition fails | ELB, RDS, or DCS AZ count | Choose a region/flavor with at least two AZs |
| Not all four replicas are Ready | Node count, topology, image pull, probes | Ensure three target nodes are ready; inspect Pod events and logs |
| HTTPS certificate error | Hostname, certificate coverage, A record | Use the covered hostname and point it to the output EIP |
| HTTPS connection fails | Certificate ID, Ingress, 443 listener | Ensure the certificate is in the same region; inspect CCE Ingress events |
| Database or cache errors | RDS/DCS state, private connectivity, password | Check VPC-only security group, endpoints, and Kubernetes Secret |
| Standard containers fail | `/var/log/litellm-bootstrap.log` | Check Docker installation, image pulls, and Compose logs |

### 3.5 Quick Uninstall

1. Back up LiteLLM configuration, database content, and audit information that must be retained. Deleting the stack deletes template-managed resources.
2. Open RFS in the corresponding region and select the stack.
3. Create a deletion plan and review its impact, then delete the stack and its resources.
4. Enter the required confirmation and execute deletion.
5. Check for residual or billable EIPs, ELB, CCE nodes, RDS, DCS, NAT, disks, and the DNS A record. The domain and pre-imported ELB certificate are not template-created; handle them under your retention policy.

---

## 4. Appendix

### 4.1 Glossary

| Term | Description |
|---|---|
| RFS | Resource Formation Service, which creates and manages stacks from templates |
| CCE Turbo | Managed Kubernetes cluster type using Cloud Native Network 2.0 |
| ELB | Elastic Load Balance; the HA public HTTPS endpoint |
| RDS | Relational Database Service; HA PostgreSQL 16 persistence |
| DCS | Distributed Cache Service; HA Redis 7.0 cache and coordination |
| NAT | Provides SNAT egress for private and ENI subnets |
| Salt Key | Encrypts sensitive LiteLLM database fields and must not change after data is stored |

### 4.2 References

- [LiteLLM Proxy Quick Start](https://docs.litellm.ai/docs/proxy/quick_start)
- [LiteLLM GitHub repository](https://github.com/BerriAI/litellm)
- [Accessing Huawei Cloud RFS](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0020.html)
- [Huawei Cloud RFS agency](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0017.html)
- [Huawei Cloud CCE cluster overview](https://support.huaweicloud.com/intl/en-us/usermanual-cce/cce_10_0430.html)
- [Huawei Cloud ELB certificates](https://support.huaweicloud.com/intl/en-us/usermanual-elb/elb_ug_zs_0001.html)
- [Huawei Cloud DNS A record rules](https://support.huaweicloud.com/intl/en-us/usermanual-dns/dns_usermanual_0601.html)

---

## 5. Revision History

| Release date | Document version | Change |
|---|---|---|
| 2026-07-10 | 01 | Combined the International standard and HA editions; documented eight regions, 17 HA parameters, HTTPS/443 certificate and DNS steps, both billing modes, and the unvalidated `_v1` candidate status. |

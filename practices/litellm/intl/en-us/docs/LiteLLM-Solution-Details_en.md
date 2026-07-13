# LiteLLM International Solution Details

> **Document version:** 01
> **Release date:** 2026-07-10
> **Site:** intl (International)
> **Deployment:** RFS one-click deployment · Standard / High Availability

> **Status:** The International HA `deploying-litellm_v1.tf` is a candidate template that has not completed validation on real Huawei Cloud resources. It must not be presented as formally released or as meeting a specific SLA.

## 1. Solution Overview

LiteLLM is a unified LLM API gateway that connects different model providers through an OpenAI-compatible interface and provides an Admin UI, master and virtual keys, usage records, and request routing. This practice offers two RFS options:

- **Standard:** LiteLLM, PostgreSQL 16, and Prometheus run through Docker Compose on one ECS for development, integration validation, and small or medium shared use.
- **High availability:** Four LiteLLM replicas run on CCE Turbo, using three nodes by default, RDS for PostgreSQL 16 primary/standby, DCS Redis 7.0 HA, and an ELB HTTPS/443 endpoint.

Site-level documentation covers both editions. English and Chinese template directories exist for eight International regions. Each regional candidate still requires validation of flavors, AZs, RFS providers, and real deployment.

## 2. Key Advantages

### 2.1 From single-node validation to multiple replicas

Standard creates one ECS. HA creates three CCE nodes by default and runs four LiteLLM replicas, allowing teams to choose a resource scope appropriate to their stage without describing a development architecture as production HA.

### 2.2 Managed state services

HA stores LiteLLM data in an RDS PostgreSQL 16 primary/standby instance and uses DCS Redis 7.0 HA for cache and routing coordination. The template requires the RDS and DCS flavors to support at least two distinct AZs.

### 2.3 A single HTTPS public endpoint

HA exposes only ELB HTTPS/443. Application port 4000 remains a cluster-internal ClusterIP. The deployer must provide an existing ELB server certificate ID and point an A record for its covered hostname to the ELB EIP output.

### 2.4 Private egress and health management

CCE nodes, RDS, and DCS are in private resource scopes. One NAT gateway and three SNAT rules provide egress for the private subnet and two ENI subnets. The LiteLLM Deployment includes readiness/liveness probes, graceful termination, and cross-AZ/cross-host topology constraints.

## 3. Architecture and Deployment Options

### 3.1 Standard architecture

```text
Internet → EIP → ECS
                  └── Docker Compose
                      ├── LiteLLM Proxy :4000
                      ├── PostgreSQL 16
                      └── Prometheus :9090
```

| Dimension | Implementation |
|---|---|
| Compute | One ECS, `c7n.2xlarge.2` by default, Ubuntu 24.04 |
| Database | PostgreSQL 16 container on ECS |
| Monitoring | Prometheus 2.53.0 container on ECS |
| Ingress | Direct EIP HTTP/4000; Prometheus HTTP/9090 |
| Disk | 200 GB SSD system disk by default |
| LiteLLM version | `ghcr.io/berriai/litellm:main-stable`, no fixed patch version |
| Recovery | Single ECS and container restart policy; no cross-node HA |

### 3.2 High-availability architecture

```text
Internet
   │ HTTPS/443
   ▼
ELB (at least two L7 AZs)
   │
CCE Turbo v1.34 (multi-AZ)
   └── LiteLLM Proxy 1.87.0 × 4
       ├── RDS PostgreSQL 16 HA
       ├── DCS Redis 7.0 HA
       └── NAT → external model services
```

| Layer | Implementation |
|---|---|
| Network | One VPC, four subnets, one security group, three EIPs, one NAT gateway |
| Ingress | One two-AZ ELB with mandatory server certificate and HTTPS/443 only |
| Container platform | CCE Turbo v1.34, multi-AZ, `cce.s2.small` by default |
| Nodes | Target three `c7n.2xlarge.2` nodes by default; pool range 1-10 |
| Application | LiteLLM 1.87.0, four replicas, 1 vCPU/4 GiB each |
| Database | RDS for PostgreSQL 16 primary/standby, 8 vCPU/16 GiB and 100 GB CLOUDSSD by default |
| Cache | DCS Redis 7.0 HA, 8 GB by default, automatic backups retained for three days |
| Egress | One NAT gateway and three SNAT rules for the private and two ENI subnets |
| Scheduling/probes | AZ and host spreading, readiness/liveness, 120-second termination grace period |

### 3.3 Deployment comparison

| Dimension | Standard | HA candidate |
|---|---|---|
| RFS template | One `litellm-standard-en-{region}.tf` per region | One `deploying-litellm_v1.tf` per region |
| Application | One LiteLLM container | Four Kubernetes replicas |
| Default compute | One ECS | Three CCE nodes |
| Database | Containerized PostgreSQL 16 | RDS PostgreSQL 16 primary/standby |
| Cache | None | DCS Redis 7.0 HA |
| Public endpoint | EIP + HTTP/4000 | ELB + HTTPS/443 |
| Certificate/domain | Not configured by template | Certificate ID required; create A record after deployment |
| Autoscaling | None | Node pool supports scaling from 1 to 10 |
| Validation | Subject to existing evidence | `_v1` candidate is not cloud-tested |

## 4. Use Cases

### 4.1 Development and API compatibility validation

Use standard to validate model configuration, OpenAI-compatible APIs, and master/virtual-key workflows. Its single ECS is not suitable for workloads requiring cross-node fault tolerance.

### 4.2 Internal enterprise model gateway

Use HA to distribute four LiteLLM replicas across three CCE nodes by default and move database/cache state to managed HA services. It fits centralized model access, team keys, and usage records.

### 4.3 Multi-model routing and fault isolation

LiteLLM enables Redis caching, shared health checks, pre-call checks, and retry policies to centrally manage model endpoints. Actual routing availability still depends on configured providers, quotas, and connectivity.

## 5. Related Solutions

| Related capability | Integration |
|---|---|
| ModelArts MaaS or other model APIs | Configure as upstream model services through the Admin UI or database |
| Cloud Eye Service (CES) | Monitor cloud resources; separately integrate CCE logs and metrics as needed |
| Cloud Certificate Manager (CCM) | Purchase or manage the ELB HTTPS server certificate |
| Domain Name Service (DNS) | Point the certificate-covered A record to the ELB EIP |

## 6. Available Regions

| Region | Name | Standard | HA candidate |
|---|---|:---:|:---:|
| `ap-southeast-1` | CN-Hong Kong | Template | `_v1` candidate |
| `ap-southeast-2` | AP-Bangkok | Template | `_v1` candidate |
| `ap-southeast-3` | AP-Singapore | Template | `_v1` candidate |
| `af-south-1` | AF-Johannesburg | Template | `_v1` candidate |
| `af-north-1` | AF-Cairo | Template | `_v1` candidate |
| `tr-west-1` | TR-Istanbul | Template | `_v1` candidate |
| `la-north-2` | LA-Mexico City2 | Template | `_v1` candidate |
| `sa-brazil-1` | LA-São Paulo1 | Template | `_v1` candidate |

“Template” only means the corresponding file exists in the repository. It does not guarantee account quota, flavor availability, or cloud validation in that region. HA also requires ELB, RDS, and DCS to satisfy the two-AZ preconditions.

## 7. Estimated Cost

No unverified amount is stated. Use the RFS execution plan and Huawei Cloud pricing calculator in the target region; the final bill prevails.

| Edition | Pay-per-use resources | Subscription resources | Additional considerations |
|---|---|---|---|
| Standard | ECS; traffic-billed EIP | ECS can use `prePaid` | EIP remains traffic-billed; include the ECS system disk |
| HA | ELB, CCE, node ECS/disks, RDS, DCS, NAT; traffic for three EIPs | ELB, CCE, nodes, RDS, DCS, and NAT can follow `prePaid` | Calculate cluster management, compute, storage, traffic, database, and cache separately |

| Purchase parameter | Allowed value |
|---|---|
| `charging_mode` | `postPaid` or `prePaid` |
| `charging_unit` | `month` or `year` |
| `charging_period` | 1-9 months; 1-3 years |

> **Cost disclaimer:** Estimates are for planning only. Actual costs depend on region, flavors, purchase period, traffic, and promotions. The actual Huawei Cloud bill prevails.

## 8. Service Highlights

| Highlight | Implementation |
|---|---|
| Unified endpoint | OpenAI-compatible API and LiteLLM Admin UI |
| Four replicas | HA Kubernetes Deployment fixes the replica count at four |
| Three nodes by default | CCE node pool targets three nodes by default and allows up to ten |
| Two-AZ preconditions | ELB, RDS, and DCS validate at least two AZs before creation |
| Managed PostgreSQL and Redis | RDS PostgreSQL 16 primary/standby + DCS Redis 7.0 HA |
| HTTPS/443 | ELB binds an existing certificate; its hostname A record points to the ELB EIP |
| Key constraints | Master Key begins with `sk-` and totals 32-64 characters; Salt Key is 32-64 and immutable after use |
| Multi-region templates | English and Chinese International implementations cover eight regions |

## References

- [LiteLLM Proxy Quick Start](https://docs.litellm.ai/docs/proxy/quick_start)
- [LiteLLM GitHub repository](https://github.com/BerriAI/litellm)
- [Huawei Cloud RFS access](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0020.html)
- [Huawei Cloud CCE cluster overview](https://support.huaweicloud.com/intl/en-us/usermanual-cce/cce_10_0430.html)
- [Huawei Cloud ELB certificates](https://support.huaweicloud.com/intl/en-us/usermanual-elb/elb_ug_zs_0001.html)
- [Huawei Cloud DNS A record rules](https://support.huaweicloud.com/intl/en-us/usermanual-dns/dns_usermanual_0601.html)

## Revision History

| Release date | Version | Change |
|---|---|---|
| 2026-07-10 | 01 | Combined standard and HA editions; documented eight regions, actual HA topology, both billing modes, and candidate-not-cloud-tested status. |

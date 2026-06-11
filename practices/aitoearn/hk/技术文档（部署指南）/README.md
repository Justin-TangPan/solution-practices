# AiToEarn，AI-Powered Content Marketing Platform — One-Click Deployment

## Solution Overview

### Application Scenarios

[AiToEarn](https://github.com/yikart/AiToEarn) is an AI-powered content marketing platform that helps creators, brands, and enterprises create, distribute, engage, and monetize content across 13+ global social media platforms.

Core capabilities:
- **Multi-Platform Publishing** — One-click publishing to TikTok, YouTube, Instagram, Facebook, Twitter/X, Pinterest, LinkedIn, and more
- **Engagement Automation** — Automated likes, bookmarks, follows, AI-powered comment replies
- **Content Creation** — AI video generation, image generation, batch matrix operations
- **Monetization Tasks** — CPS/CPE/CPM settlement models

### Architecture

```
ECS (Hong Kong, 8vCPU 16GB)
├── Docker Compose (12 containers)
│   ├── MongoDB          ← Database
│   ├── Redis            ← Cache
│   ├── RustFS           ← S3-compatible storage
│   ├── aitoearn-ai      ← AI service
│   ├── aitoearn-server  ← Backend
│   ├── aitoearn-web     ← Frontend
│   ├── Nginx            ← Reverse proxy
│   └── Init containers ×5
└── Port: 8080 (Web)
```

### Key Benefits

- **One-Click Deployment** — 12 containers auto-orchestrated, ready to use
- **Global Platform Coverage** — 13+ major social media platforms worldwide
- **AI-Powered** — Built-in AI models for video/image generation, smart comments
- **Self-Hosted** — Data stays on your own server, fully private

### Constraints

- Requires 8vCPU 16GB+ ECS spec (12 containers are resource-intensive)
- Social media OAuth credentials must be obtained by the user
- AI features require corresponding API keys

## Resource and Cost Planning

| Huawei Cloud Service | Configuration | Qty | Estimated Monthly Cost |
|---------------------|---------------|-----|----------------------|
| Flexus X Instance | x1.8u.16g, Ubuntu 24.04, 100GB SAS | 1 | ≈$140 |
| Elastic IP | 300Mbit/s, traffic billing | 1 | varies |
| VPC + Subnet + Security Group | Default | 1 | $0.00 |
| **Total** | — | — | **≈$140/month + traffic** |

## Implementation Steps

1. [Preparation](#preparation)
2. [Quick Deployment](#quick-deployment)
3. [Getting Started](#getting-started)
4. [Quick Uninstall](#quick-uninstall)

## Preparation

- Register a Huawei Cloud account and complete identity verification
- Account must not be in arrears or frozen

## Quick Deployment

1. Log in to Huawei Cloud Console → RFS → Create Stack
2. Upload `deploying-aitoearn.tf`
3. Fill in parameters (ECS password required)
4. Click Create, wait ~10-15 minutes

## Getting Started

After deployment, access `http://YOUR_EIP:8080` in your browser.

### Configure Social Media Accounts

1. Log in to AiToEarn dashboard
2. Go to "Account Management", add social media accounts
3. Complete OAuth authorization as prompted

### Configure AI Features (Optional)

To use AI content creation, configure API keys in `/opt/aitoearn/`.

## Quick Uninstall

1. Log in to RFS Console
2. Find the stack → Delete → Delete Resources → Type `Delete` → Confirm

## Appendix

### Glossary

| Term | Description |
|------|-------------|
| **Flexus X Instance** | Huawei Cloud's next-generation flexible compute instance |
| **Elastic Cloud Server (ECS)** | On-demand elastic computing service |
| **Docker Compose** | Multi-container orchestration tool |
| **MongoDB** | NoSQL document database |
| **Redis** | In-memory cache database |
| **RustFS** | S3-compatible object storage |

## Revision History

| Release Date | Revision Notes |
|-------------|---------------|
| 2026-06-05 | Initial release |

## More Resources

- [AiToEarn GitHub](https://github.com/yikart/AiToEarn) — Source code, docs
- [AiToEarn Website](https://aitoearn.ai) — Online version
- [Huawei Cloud RFS](https://support.huaweicloud.com/tr-aos/rf_05_0001.html) — Resource Formation Service

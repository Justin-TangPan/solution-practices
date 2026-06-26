# Claude Code + Headroom，The Frugal Coding Assistant — One-Click Deployment

## Solution Overview

### Application Scenarios

This solution targets developers using Claude Code for AI-assisted programming. By deploying [Headroom](https://github.com/chopratejas/headroom) as a context compression proxy, it solves two core pain points:

- **Context Overflow** — Long conversations, large file reads, and multi-turn tool calls cause the context window to fill rapidly, forcing session interruptions
- **Excessive Token Costs** — Each conversation turn carries the full context (including history), with code files often spanning thousands of lines, causing token costs to grow linearly

Headroom acts as a proxy layer between Claude Code and the LLM API, automatically compressing tool outputs, file contents, conversation history, and logs before data reaches the model. Tested compression rates: 60-95% with no loss in answer quality.

### Architecture

```
User Terminal
  │
  ▼
Claude Code CLI (on ECS)
  │ ANTHROPIC_BASE_URL=http://localhost:8787
  ▼
Headroom Proxy (local background process, port 8787)
  │ Compress context 60-95%
  │ ANTHROPIC_TARGET_API_URL=https://api.modelarts-maas.com/anthropic
  ▼
Huawei Cloud MaaS API
  │
  ▼
LLM Inference (DeepSeek / Claude / ...)
```

**Key Configuration:**

| Config | Value | Purpose |
|--------|-------|---------|
| `ANTHROPIC_BASE_URL` | `http://localhost:8787` | Claude Code → Headroom proxy |
| `ANTHROPIC_TARGET_API_URL` | `https://api.modelarts-maas.com/anthropic` | Headroom proxy → MaaS upstream |
| `ANTHROPIC_AUTH_TOKEN` | MaaS API Key | Authentication |
| `ANTHROPIC_MODEL` | `deepseek-v3.2` | Model to use |

**Deployed Resources:**

| Resource | Description |
|----------|-------------|
| Elastic IP (EIP) | Public network access for SSH and API calls |
| Flexus X Instance (ECS) | Hosts Headroom proxy and Claude Code |
| Security Group | Allows SSH(22), Headroom proxy(8787), ICMP |
| VPC + Subnet | Isolated virtual network |

### Key Benefits

- **60-95% Token Savings** — Proven on real agent workloads; code search compressed from 17,765 to 1,408 tokens
- **Zero Code Changes** — Drop-in proxy, transparent to Claude Code; no code modifications needed
- **Reversible Compression** — Originals stored locally; LLM can retrieve on demand via `headroom_retrieve`
- **AST-Aware** — Intelligent syntax tree-level compression for Python, JS, TS, Go, Rust, Java, C++
- **Built-in Monitoring** — `/stats`, `/metrics` (Prometheus), `/stats-history` endpoints included
- **One-Click Deployment** — Headroom proxy + Claude Code pre-installed; just add API Key
- **Enterprise Security** — Data processed locally, supports private deployment

### Constraints and Limitations

- Users must register a Huawei Cloud account and complete identity verification.
- Account must not be in arrears or frozen.
- MaaS service must be activated on the ModelArts platform to obtain an API Key.
- Claude Code is used via SSH terminal, not a web interface.
- Compression effectiveness varies by workload; log-intensive scenarios achieve the highest rates (92%), code exploration scenarios around 47%.

## Resource and Cost Planning

| Huawei Cloud Service | Resource Name | Configuration | Qty | Estimated Monthly Cost |
|---------------------|---------------|---------------|-----|----------------------|
| VPC | headroom-claude-code-vpc | 172.16.0.0/16, Hong Kong | 1 | $0.00 |
| Subnet | headroom-claude-code-subnet | 172.16.1.0/24 | 1 | $0.00 |
| Security Group | headroom-claude-code-sg | ICMP, SSH(22), Proxy(8787) | 1 | $0.00 |
| Flexus X Instance | headroom-claude-code-ecs | x1.2u.4g, Ubuntu 24.04, 40GB SAS | 1 | ≈$36.50 |
| Elastic IP | headroom-claude-code-eip | Dynamic BGP, 300Mbit/s, traffic billing | 1 | varies |
| **Total** | — | — | — | **≈$36.50 + traffic** |

> MaaS token costs are separate, billed by actual usage. Headroom reduces these costs by 60-95%.

### ROI Calculation

For a 10-person R&D team:

| Item | Before | After | Savings |
|------|-------|-------|---------|
| Monthly Token Cost | $1,400 | $140 - $560 | $840 - $1,260 |
| Annual Token Cost | $16,800 | $1,680 - $6,720 | $10,080 - $15,120 |
| ECS Server Cost | — | $474/year | — |
| **Annual Net Savings** | — | — | **$9,606 - $14,646** |

## Implementation Steps

1. [Preparation](#preparation) — Create RFS delegation (if needed)
2. [Quick Deployment](#quick-deployment) — One-click deploy via RFS
3. [Getting Started](#getting-started) — Configure MaaS API Key, start Claude Code
4. [Quick Uninstall](#quick-uninstall) — Delete resource stack, release all resources

## Preparation

If using a newly registered Huawei Cloud account, skip to [Quick Deployment](#quick-deployment).

If using an IAM sub-user, verify the user is in the admin user group. If not, refer to [IAM Permission Management](https://support.huaweicloud.com/usermanual-iam/iam_01_0001.html).

### Create rf_admin_trust Delegation (Optional)

1. Log in to [Management Console](https://console.huaweicloud.com/console/?region=cn-north-4), hover over your account, click "Unified Identity Authentication".
2. Navigate to "Delegations", search for `rf_admin_trust`.
   - If exists → skip
   - If not → continue with step 3
3. Click "Create Delegation", name `rf_admin_trust`, type "Cloud Service", enter `RFS`, click "Complete".
4. Click "Authorize Now".
5. Search `Tenant Administrator`, check result, click "Next".
6. Select "All Resources", click "Confirm".

## Quick Deployment

### Operation Steps

1. Log in to [Huawei Cloud Solution Practice](https://solution.huaweicloud.com/), search "Headroom + Claude Code", click "Start Deployment".
2. Click deploy button, review Flexus X instance settings, configure server password.
3. Click "One-Click Deploy". Ensure sufficient account balance.
4. Wait for "Apply required resource success" in Events log. Wait ~10 minutes for deployment script.

### Deployment Verification

After deployment, SSH into ECS and verify:

```bash
headroom --version          # Should show version
claude --version            # Should show version
curl http://localhost:8787/readyz  # Should return status: healthy
```

## Getting Started

### Step 1: Activate Huawei Cloud MaaS

1. Go to [ModelArts MaaS Console](https://console.huaweicloud.com/modelarts/?region=cn-southwest-2#/model-service/maas).
2. Activate MaaS service (if not already).
3. Create API Key:
   - Click "API Key Management" → "Create API Key".
   - Copy and save securely (shown only once).

> MaaS is hosted in Guiyang region but the API endpoint is publicly accessible from any region.

### Step 2: Configure Environment Variables

SSH into ECS, add the following to `/root/.bashrc` (replace `your-maas-api-key` with your actual key):

```bash
cat >> /root/.bashrc << 'EOF'
export ANTHROPIC_AUTH_TOKEN="your-maas-api-key"
export ANTHROPIC_BASE_URL="http://localhost:8787"
export ANTHROPIC_TARGET_API_URL="https://api.modelarts-maas.com/anthropic"
export ANTHROPIC_MODEL="deepseek-v3.2"
EOF
source /root/.bashrc
```

**Explanation:**

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_AUTH_TOKEN` | MaaS API Key, sent by Claude Code with each request |
| `ANTHROPIC_BASE_URL` | Claude Code sends requests to local proxy `localhost:8787` |
| `ANTHROPIC_TARGET_API_URL` | Headroom proxy forwards compressed requests to MaaS |
| `ANTHROPIC_MODEL` | Model name to use |

### Step 3: Start Claude Code

```bash
claude
```

Claude Code reads `ANTHROPIC_BASE_URL` from environment and connects to the local Headroom proxy.

### Step 4: Verify Full Chain

Send any message in Claude Code (e.g. "hello"), then check in another terminal:

```bash
curl -s http://localhost:8787/stats | grep -o '"api_requests":[0-9]*'
```

Expected: `api_requests` > 0, meaning requests went through Headroom proxy.

### Step 5: Switch Model (Optional)

Edit `ANTHROPIC_MODEL` in `/root/.bashrc`, then `source /root/.bashrc`:

```bash
export ANTHROPIC_MODEL="claude-sonnet-4-20250514"
```

Available models depend on MaaS subscription:

| Model | Best For |
|-------|----------|
| `deepseek-v3.2` | Cost-effective, general coding |
| `claude-sonnet-4-20250514` | Complex reasoning, architecture design |

### Step 6: Monitor Token Savings

```bash
headroom perf
curl http://localhost:8787/stats
curl http://localhost:8787/metrics
```

### Common Commands

```bash
# Start Claude Code (need source /root/.bashrc first)
claude

# Check proxy status
curl http://localhost:8787/health

# Check proxy stats (api_requests should be >0)
curl http://localhost:8787/stats

# View proxy logs
tail -f /var/log/headroom-proxy.log

# Restart proxy
pkill headroom
export ANTHROPIC_TARGET_API_URL=https://api.modelarts-maas.com/anthropic
nohup headroom proxy --host 0.0.0.0 --port 8787 > /var/log/headroom-proxy.log 2>&1 &
```

## Best Practices

### Model Selection Strategy

| Scenario | Recommended Model | Reason |
|----------|------------------|--------|
| Daily coding, code completion | `deepseek-v3.2` | Cost-effective, fast response |
| Complex refactoring, architecture | `claude-sonnet-4-20250514` | Strong reasoning capability |
| Code review, bug fixing | `deepseek-v3.2` | Sufficient and economical |
| Cross-module analysis | `claude-sonnet-4-20250514` | Needs global understanding |

### Compression Rate Optimization

Different workloads achieve different compression rates:

| Workload | Expected Rate | Optimization |
|----------|---------------|--------------|
| Code Search | 92% | No optimization needed |
| File Content | 88% | No optimization needed |
| Log Analysis | 92% | No optimization needed |
| Chat History | 89% | No optimization needed |
| Code Exploration | 47% | Use `headroom_retrieve` to get original |

### Monitoring Recommendations

Set up the following monitoring alerts:

| Monitor | Threshold | Action |
|---------|-----------|--------|
| Health Check | 3 consecutive failures | Restart proxy |
| Disk Usage | > 80% | Clean old data |
| API Requests | Abnormal growth | Check for unusual calls |

## Troubleshooting

### headroom: command not found

**Cause:** Ubuntu 24.04 PEP 668 blocks pip system-wide installs.

**Fix:**
```bash
pip3 install headroom-ai fastapi uvicorn 'httpx[http2]' transformers \
  --break-system-packages --ignore-installed
```

### ModuleNotFoundError: No module named 'fastapi' / 'transformers'

**Cause:** headroom-ai dependencies not fully installed.

**Fix:**
```bash
pip3 install fastapi uvicorn 'httpx[http2]' transformers \
  --break-system-packages --ignore-installed
```

### Headroom proxy exits immediately after start

**Cause:** Missing h2 package (HTTP/2 support).

**Fix:**
```bash
pip3 install h2 --break-system-packages
```

Check logs:
```bash
tail -20 /var/log/headroom-proxy.log
```

### Claude Code sends messages but stats show no change

**Cause:** `ANTHROPIC_BASE_URL` not in Claude Code's process environment; requests bypass the proxy.

**Fix:**
```bash
echo $ANTHROPIC_BASE_URL    # If empty, env vars not loaded
source /root/.bashrc        # Reload
claude                      # Try again
```

Or pass directly on command line:
```bash
ANTHROPIC_BASE_URL=http://localhost:8787 claude
```

### Proxy responds slowly

**Cause:** Network latency or slow MaaS response.

**Troubleshooting:**
```bash
# Check network latency to MaaS
ping api.modelarts-maas.com

# Check proxy logs for latency info
grep "latency" /var/log/headroom-proxy.log

# Check system resource usage
top -bn1 | head -20
```

### Verify Deployment Status

```bash
headroom --version                    # Headroom CLI
claude --version                      # Claude Code
curl http://localhost:8787/readyz     # Proxy health
echo $ANTHROPIC_BASE_URL              # Should be http://localhost:8787
echo $ANTHROPIC_TARGET_API_URL        # Should be https://api.modelarts-maas.com/anthropic
echo $ANTHROPIC_AUTH_TOKEN             # Should be MaaS API Key
```

## Security Best Practices

### Network Security

- **Restrict SSH Source IP**: Limit SSH(22) port source IP in security group
- **Don't Expose Proxy Port**: Port 8787 is for local access only, not recommended for public exposure
- **Use VPC**: All resources deployed in isolated VPC

### Data Security

- **Local Data Processing**: All code and data processed locally on ECS, never leaves the instance
- **API Key Protection**: Sensitive information passed via environment variables, not hardcoded
- **Regular Key Rotation**: Recommend regular rotation of MaaS API keys

### Access Control

- **Least Privilege**: Grant only necessary IAM permissions
- **Audit Logs**: Enable CloudTrail to record all API calls
- **Multi-Factor Authentication**: Recommend enabling MFA for Huawei Cloud account

## Quick Uninstall

1. Log in to [RFS Console](https://console.huaweicloud.com/rfs/).
2. Locate the resource stack, click "Delete".
3. Select "Delete Resources", type `Delete`, click "Confirm".

## Appendix

### Glossary

| Term | Description |
|------|-------------|
| **Flexus X Instance** | Huawei Cloud's next-generation flexible compute instance for SMBs and developers |
| **Elastic Cloud Server (ECS)** | On-demand elastic computing service |
| **Virtual Private Cloud (VPC)** | Isolated, private virtual network on Huawei Cloud |
| **Elastic IP (EIP)** | Independent public IP address and bandwidth resources |
| **Headroom** | Open-source context compression proxy that reduces LLM token consumption |
| **Claude Code** | Anthropic's official CLI programming tool |
| **MaaS** | Model as a Service — Huawei Cloud's model platform |
| **AST** | Abstract Syntax Tree — tree representation of code structure |

### More Resources

- [Headroom GitHub](https://github.com/chopratejas/headroom) — Source code, docs, benchmarks
- [Headroom Documentation](https://headroom-docs.vercel.app) — Full configuration reference
- [Huawei Cloud MaaS](https://support.huaweicloud.com/model-call-maas/model-call-060.html) — MaaS API setup guide
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code) — Claude Code official docs
- [Huawei Cloud RFS](https://support.huaweicloud.com/tr-aos/rf_05_0001.html) — Resource Formation Service

## Revision History

| Release Date | Revision Notes |
|-------------|---------------|
| 2026-06-05 | Full chain verified, updated dependencies and configuration |
| 2026-06-11 | Added ROI calculation, best practices, security recommendations, more troubleshooting |

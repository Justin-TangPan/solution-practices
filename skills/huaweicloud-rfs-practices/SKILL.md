---
name: huaweicloud-rfs-practices
description: |
  Create and maintain Huawei Cloud RFS (Resource Formation Service) / OpenTofu solution
  templates and deployment scripts. Use this skill whenever the user:
  - Creates a new Huawei Cloud solution implementation template (.tf.json)
  - Writes user_data bootstrap scripts or install shell scripts for ECS deployment
  - Debugs deployment failures (Docker install hangs, GPG issues, apt prompts, image pulls)
  - Adds random/unique naming, security groups, OBS uploads for RFS templates
  - Needs to upload install scripts to an OBS bucket for RFS deployment
  - Asks about "华为云解决方案实践", "RFS模板", "部署脚本", "tf.json",
    "resources formation", or "一键部署" templates.
  Also triggers when the user mentions "demo patterns", "antipitfall", or references
  the n8n, Dify, or Hermes solution deployment experiences.
---

# Huawei Cloud RFS Solution Builder

Build production-ready Huawei Cloud RFS (Resource Formation Service) solution templates.
Follow standards from `assets/demo/` reference projects plus accumulated field-tested fixes.

## Workflow

When asked to create or fix a Huawei Cloud RFS solution:

1. **Understand the application**: What ports? What dependencies? Bare-metal or Docker? OpenAI/LLM key needed?
2. **Write the tf.json**: Variables → data sources → VPC/subnet/secgroup → EIP → ECS with user_data
3. **Write the install script**: 4-stage shell script (prepare → Docker → config → start)
4. **Upload to OBS**: Both `.tf.json` and install script to the project's OBS bucket
5. **Test with RFS**: Deploy, SSH in, check logs at `/var/log/n8n-deploy/`

## tf.json Template Standards

Reference files: `assets/demo/` directory contains three reference projects.

### Required Structure (top-level keys)

```json
{
    "terraform": { "required_providers": { ... } },
    "provider": { "huaweicloud": { ... } },
    "variable": { ... },
    "data": { ... },
    "resource": { ... },
    "output": { ... }
}
```

### Provider Configuration

```json
"terraform": {
    "required_providers": {
        "huaweicloud": {
            "source": "huawei.com/provider/huaweicloud",
            "version": ">=1.70.1"
        }
    }
},
"provider": {
    "huaweicloud": {
        "cloud": "myhuaweicloud.com",
        "region": "cn-north-4",
        "insecure": true,
        "auth_url": "https://iam.cn-north-4.myhuaweicloud.com/v3"
    }
}
```

**CRITICAL:** `required_providers` is an **OBJECT** keyed by provider name — NOT an array `[{...},{...}]`. Huawei Cloud RFS only supports the `huaweicloud` provider. Do NOT add `random`, `tls`, or any other HashiCorp provider.

### Required Variables (7 core variables present in all demos)

| Variable | Type | Default | Validation |
|----------|------|---------|------------|
| `vpc_name` | string | `"{project}-demo"` | 1-54 chars, Chinese/alphanumeric/underscore/hyphen/dot |
| `security_group_name` | string | `"{project}-demo"` | 1-64 chars |
| `ecs_name` | string | `"{project}-demo"` | 1-64 chars |
| `ecs_flavor` | string | `"x1.4u.8g"` | Regex `x1.?u.?g` or ECS flavor format |
| `ecs_password` | string (sensitive) | `""` | 8-26 chars, 3 of 4 char types |
| `system_disk_size` | number | `60` or `100` | Range 40-1024 |
| `bandwidth_size` | number | `10` or `300` | Range 1-300 |
| `charging_mode` | string | `"postPaid"` | `["postPaid","prePaid"]` |
| `charging_unit` | string | `"month"` | `["month","year"]` |
| `charging_period` | number | `1` | 1-9 (month) or 1-3 (year) |

### Unique Naming (Anti-conflict)

Append a random suffix to ALL resource names for multi-deployment safety:

```json
"locals": {
    "name_suffix": "${substr(uuid(), 0, 8)}"
}
```

Then use in all resource names:
```json
"name": "${var.vpc_name}-${local.name_suffix}"
"name": "${var.vpc_name}-${local.name_suffix}-subnet"
"name": "${var.security_group_name}-${local.name_suffix}"
"name": "${var.ecs_name}-${local.name_suffix}"
```

Do NOT use `random_id` resource — the `random` provider is not available in Huawei Cloud RFS. Use `substr(uuid(), 0, 8)` in locals instead.

### Data Sources

Always include:
```json
"data": {
    "huaweicloud_images_image": {
        "Ubuntu": {
            "most_recent": true,
            "name": "Ubuntu 22.04 server 64bit",
            "visibility": "public"
        }
    }
}
```

### VPC/Subnet (standard pattern)

```json
"huaweicloud_vpc": {
    "vpc": {
        "name": "${var.vpc_name}-${local.name_suffix}",
        "cidr": "172.16.0.0/16"
    }
},
"huaweicloud_vpc_subnet": {
    "subnet": {
        "name": "${var.vpc_name}-${local.name_suffix}-subnet",
        "cidr": "172.16.1.0/24",
        "gateway_ip": "172.16.1.1",
        "vpc_id": "${huaweicloud_vpc.vpc.id}"
    }
}
```

### Security Group (core rules + app ports)

Always include these two mandatory rules:
```json
"allow_ping": { "protocol": "icmp", "remote_ip_prefix": "0.0.0.0/0" },
"cloud_shell": { "protocol": "tcp", "ports": 22, "remote_ip_prefix": "121.36.59.153/32" }
```

Add app-specific rules for each port the application listens on.

### ECS (compute instance standard)

```json
"huaweicloud_compute_instance": {
    "compute_instance": {
        "name": "${var.ecs_name}-${local.name_suffix}",
        "image_id": "${data.huaweicloud_images_image.Ubuntu.id}",
        "flavor_id": "${var.ecs_flavor}",
        "security_group_ids": ["${huaweicloud_networking_secgroup.secgroup.id}"],
        "system_disk_type": "SAS",
        "system_disk_size": "${var.system_disk_size}",
        "admin_pass": "${var.ecs_password}",
        "delete_disks_on_termination": true,
        "network": { "uuid": "${huaweicloud_vpc_subnet.subnet.id}" },
        "agent_list": "hss,ces",
        "eip_id": "${huaweicloud_vpc_eip.vpc_eip.id}",
        "charging_mode": "${var.charging_mode}",
        "period_unit": "${var.charging_unit}",
        "period": "${var.charging_period}",
        "tags": { "app": "{app-name}" },
        "user_data": "..."
    }
}
```

### user_data Pattern (minimal bootstrap)

Keep user_data to an absolute minimum. Only reset password + download + execute:

```bash
#!/bin/bash
echo 'root:${var.ecs_password}' | chpasswd
LOG="/var/log/n8n-bootstrap.log"
exec > >(tee -a "$LOG") 2>&1
SCRIPT="/tmp/install.sh"
curl -fsSL -o "$SCRIPT" "https://{BUCKET}.obs.{REGION}.myhuaweicloud.com/install_{app}.sh"
chmod +x "$SCRIPT"
bash "$SCRIPT" "${var.app_version}"
RC=$?
echo "[$(date)] Bootstrap: finished (exit=$RC)"
exit $RC
```

This pattern lets you update the install script without re-releasing the RFS template.
The script is hosted on OBS (any bucket with public-read access).

### Output

```json
"output": {
    "说明": {
        "depends_on": ["huaweicloud_vpc_eip.vpc_eip"],
        "value": "等待应用部署完毕（约{minutes}分钟）后，在浏览器输入 http://${huaweicloud_vpc_eip.vpc_eip.address}:{port}/ 访问。SSH：ssh root@${huaweicloud_vpc_eip.vpc_eip.address}，日志：/var/log/n8n-deploy/"
    }
}
```

---

## Install Shell Script Pattern (4 Stages)

The install script is hosted on OBS and downloaded by user_data. Use this proven 4-stage pattern:

### Stage 1: System Prepare
- `dpkg --configure -a` (pre-cleanup)
- `apt-get update && apt-get install base-packages` 
- Install `software-properties-common` for `add-apt-repository`

### Stage 2: Docker Install
- Use Huawei Cloud Docker CE mirror ONLY
- Install `docker-ce` + `docker-compose` (v1) from Huawei mirror
- Configure `daemon.json` with Huawei Cloud SWR + domestic mirrors
- Restart Docker daemon

### Stage 3: Application Config
- Create directories, set permissions
- Write docker-compose.yaml
- Create backup script + crontab

### Stage 4: Start Application
- `docker-compose pull && docker-compose up -d`
- Health check loop (max 120s)
- Dump logs if health check fails

### Logging

Each stage writes to its own log file under `/var/log/n8n-deploy/`:
```
/var/log/n8n-bootstrap.log          # user_data bootstrap
/var/log/n8n-deploy/
    ├── 01-prepare.log
    ├── 02-docker.log
    ├── 03-setup.log
    ├── 04-start.log
    └── run-all.log
```

---

## Pitfalls & Anti-Pitfall Fixes

These are field-tested fixes for issues encountered during real deployments.

### Pitfall 1: sshd_config TUI Blocks Deployment

**Symptom:** RFS deploys but gets stuck. SSH in and see:
```
A new version of configuration file /etc/ssh/sshd_config is available.
What do you want to do about modified configuration file sshd_config?
```

**Root cause:** `DEBIAN_FRONTEND=noninteractive` only suppresses debconf prompts, not dpkg conffile prompts.

**Fix:** Add three layers of protection before EVERY apt-get command:
```bash
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
APT_OPTS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
dpkg --configure -a 2>/dev/null || true   # Pre-cleanup
apt-get $APT_OPTS install <packages>
```

### Pitfall 2: Docker CE GPG Key Download Fails  

**Symptom:** `curl: (35) SSL connect error` or `gpg: no valid OpenPGP data found` when pulling from `download.docker.com`

**Root cause:** Docker's official GPG key server and APT repo are blocked from China ECS.

**Fix:** Use Huawei Cloud's own Docker CE mirror:
```bash
curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | \
    gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
    https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install docker-ce docker-compose
```

Do NOT use `docker.io` from Ubuntu repo (no compose v2 plugin, old version).  
Do NOT use Aliyun/Tsinghua Docker CE mirrors (GPG key may also fail).

### Pitfall 3: docker compose vs docker-compose

**Symptom:** `docker: unknown command: docker compose`

**Root cause:** Huawei Docker CE mirror provides `docker-compose` (v1 standalone binary), not the Docker Compose v2 CLI plugin.

**Fix:** Use `docker-compose` (hyphenated) everywhere:
```bash
docker-compose pull
docker-compose up -d
docker-compose ps
```

### Pitfall 4: Docker Image Pull Fails from China

**Symptom:** `dial tcp 173.208.182.68:443: i/o timeout` when pulling from Docker Hub

**Fix:** Configure Docker daemon with domestic registry mirrors:
```json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://{project-hash}.mirror.swr.myhuaweicloud.com"
  ]
}
```

The SWR mirror must be created per-project. Use `docker.1ms.run` as universal fallback.

### Pitfall 5: Container Permission Denied (EACCES)

**Symptom:** Container keeps restarting. Logs show:
```
Error: EACCES: permission denied, open '/home/node/.n8n/config'
```

**Root cause:** Container runs as non-root user (e.g., UID 1000 for n8n), but host-mounted volume is owned by root.

**Fix:** After creating directories, chown them:
```bash
mkdir -p /opt/n8n/data /opt/n8n/backup
chown -R 1000:1000 /opt/n8n/data
```

### Pitfall 6: Secure Cookie Blocks HTTP Login  

**Symptom:** n8n shows "设置了安全cookie，但通过不安全网址访问" message, can't login.

**Fix:** Add to container environment:
```yaml
environment:
  - N8N_SECURE_COOKIE=false
```

### Pitfall 7: required_providers JSON Format Error  

**Symptom:** `Duplicate required providers configuration`

**Root cause:** `required_providers` written as array `[{huaweicloud:{...}}, {random:{...}}]` instead of object.

**Fix:** Always use object format:
```json
"required_providers": {
    "huaweicloud": { "source": "...", "version": "..." }
}
```

### Pitfall 8: Random Provider Not Available  

**Symptom:** `provider hashicorp/random was not found`

**Root cause:** Huawei Cloud RFS only supports the `huaweicloud` provider. HashiCorp providers are not in Huawei's registry.

**Fix:** Use `substr(uuid(), 0, 8)` in `locals` instead of `random_id` resource.

### Pitfall 9: VPC/ECS Name Conflicts  

**Symptom:** Can't deploy a second instance due to name collisions.

**Fix:** Append `-${local.name_suffix}` to every resource name in the tf.json.
See section "Unique Naming" above.

### Pitfall 10: Static OBS Script Blocks Iteration  

**Symptom:** Every script change requires re-creating the RFS template zip.

**Fix:** user_data only downloads + executes. The real install logic lives in the OBS-hosted `.sh` file. Update the OBS file to fix bugs without touching the RFS template.

### Pitfall 11: pip/PyPI Timeout from China ECS  

**Symptom:** `pip install` hangs or times out. Ansible or other Python packages fail to install in a deploy script, stalling the whole deployment for 30+ minutes.

**Root cause:** Default PyPI server (pypi.org) is slow or unreachable from China ECS. The `pip install -q` flag makes it appear hung without visible progress — but the process is just waiting on timeout.

**Fix:** Always use a domestic PyPI mirror in install scripts:
```bash
PIP_MIRROR="-i https://pypi.tuna.tsinghua.edu.cn/simple"
python3 -m pip install $PIP_MIRROR --upgrade ansible
```

Available mirrors:
- `https://pypi.tuna.tsinghua.edu.cn/simple` (Tsinghua — most reliable for general use)
- `https://mirrors.aliyun.com/pypi/simple/` (Aliyun — used by ocboot's `-m` flag)

For tools that wrap pip (like ocboot's run.py), pass the mirror via their own flag:
```bash
./run.py -m "https://mirrors.aliyun.com/pypi/simple/" cmp <host_ip>
```

**Detect stuck pip:** `ps aux | grep pip` — if a pip process has been running >5 min with near-zero CPU or network activity, kill it (`kill -9 <pid>`) and retry with mirror flag. Never use `pip install -q` in China ECS scripts; always specify a mirror.

---

## OBS Upload

Use Python SDK to upload files to the project's OBS bucket:

```python
from obs import ObsClient
c = ObsClient(
    access_key_id='AK',
    secret_access_key='SK',
    server='https://obs.cn-south-1.myhuaweicloud.com',
    path_style=False
)
c.putFile('bucket-name', 'remote-name.sh', '/local/path.sh')
c.close()
```

Upload three files for each solution:
1. `install_{app}.sh` — the 4-stage deployment script
2. `deploying-{app}.tf.json` — the RFS template
3. `{app}-platform.zip` — project archive containing both + README

---

## Validation Checklist

Before deploying, verify:
- [ ] `required_providers` is an object, not array
- [ ] Only `huaweicloud` provider listed (no `random`, `tls`, etc.)
- [ ] All resource names include `-${local.name_suffix}`
- [ ] `DEBCONF_NONINTERACTIVE_SEEN=true` in Stage 1 and Stage 2
- [ ] `--force-confdef --force-confold` on every apt-get command
- [ ] `dpkg --configure -a` before first apt operation
- [ ] Docker CE from `mirrors.huaweicloud.com` (not docker.com)
- [ ] `docker-compose` (v1) commands, not `docker compose` (v2)
- [ ] `registry-mirrors` configured in daemon.json
- [ ] `chown -R UID:GID` on app data directory
- [ ] `N8N_SECURE_COOKIE=false` (for n8n specifically)
- [ ] user_data is minimal: download + execute only
- [ ] Output section references correct log path `/var/log/n8n-deploy/`

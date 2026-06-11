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

1. **Confirm decision points** (see Decision Points section below) — ask user for non-default choices
2. **Write the .tf template**: Variables → locals (name_suffix) → data sources → VPC/subnet/secgroup → EIP → ECS with minimal user_data
3. **Write the install script**: Independent `.sh` file with all deployment logic
4. **Write README.md**: Follow the 9-section Hermes deployment guide format (Decision 6)
5. **Upload to OBS**: Template + script + README, naming per Decision 7
6. **Test with RFS**: Deploy, SSH in, verify services

### Template-Script Separation Rule

The `.tf` file's `user_data` must be **minimal** — only:
1. Reset ECS password
2. Download install script from OBS
3. Execute the script
4. Clean up

```hcl
user_data = "#!/bin/bash\necho 'root:${var.ecs_password}' | chpasswd\nwget -P /home/ https://{bucket}.obs.{region}.myhuaweicloud.com/{project}/install_{app}.sh\nbash /home/install_{app}.sh\nrm -rf /home/install_{app}.sh"
```

All deployment logic (package installation, configuration, service startup) belongs in the `.sh` script, NOT in the `.tf` file.

## Development Workflow (SAC 标准流程)

```
洞察（用户）→ 技术评估（AI）→ 方案设计（AI）→ 用户拍板 → 开发（AI）→ 测试 OBS 上传 → 用户测试 → 生产打包 → 用户上传生产 OBS → RFS 上线
```

### 阶段详解

| 阶段 | 负责人 | 产出 |
|------|--------|------|
| 1. 洞察 | 用户 | 明确要做的方案、目标用户、核心价值 |
| 2. 技术评估 | AI | 可行性分析、技术栈评估、依赖清单 |
| 3. 方案设计 | AI | 技术方案（单机/高可用/云服务接入）+ 业务方案（上线区域、语言） |
| 4. 拍板敲定 | 用户 | 确认方案、决策点 |
| 5. 开发 | AI | .tf 模板 + .sh 脚本 + README.md + .docx |
| 6. 测试 OBS 上传 | AI | 上传到测试桶 `tp-00940108`，用户验证 |
| 7. 用户测试 | 用户 | 在测试 OBS 上部署验证 |
| 8. 生产打包 | AI | 整理最终归档包，预置生产 OBS 路径的模板 |
| 9. 用户上传生产 | 用户 | 亲自上传到生产 OBS 桶，生成 RFS URL |

### OBS 桶规范

| 环境 | 桶 | 用途 | 操作人 |
|------|-----|------|--------|
| 测试 | `tp-00940108` | 开发阶段上传，用户测试验证 | AI |
| 生产 | 用户指定 | 最终上线，RFS URL 指向此桶 | 用户亲自上传 |

### 最终交付物

每个方案最终交付：
1. **RFS 页面 URL** — 预置好模板和参数，用户点击即可部署
2. **归档包** — `{project}-platform.zip`，包含 cn/ + hk/ 全部文件
3. **安装脚本** — `install_{app}.sh`，按区域分 cn/ 和 hk/

### RFS URL 格式

```
https://console.huaweicloud.com/rf/?region={region}&locale=zh-cn#/console/stack/stackCreate?templateUrl=https://{production-bucket}.obs.{region}.myhuaweicloud.com/{path}/deploying-{app}.tf&stackName={project}&stackDescription={description}
```

示例：
```
https://console.huaweicloud.com/rf/?region=ap-southeast-1&locale=zh-cn#/console/stack/stackCreate?templateUrl=https://documentation-samples-5.obs.ap-southeast-1.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-module/headroom-claudecode/headroom-claude-code/hk/deploying-headroom.tf&stackName=headroom-claude-code&stackDescription=ClaudeCode+Headroom
```

**注意：** RFS URL 中的 `templateUrl` 指向生产 OBS 桶，不是测试桶。用户需亲自上传到生产桶。

### 生产交付流程

1. AI 在 `release/{project}/` 目录下预置最终模板（templateUrl 已指向生产 OBS 路径）
2. AI 生成 `url.txt`，包含 TF 链接、SH 链接、RFS 页面链接
3. 用户将 `release/{project}/` 目录下的文件上传到生产 OBS 桶
4. 用户点击 RFS URL 验证部署

## User Constraints (用户约束)

以下约束必须遵守，不可违反：

### 1. reference/ 目录只读

`solution-implementations/reference/` 目录仅用户可修改。AI 不得主动修改此目录下的任何文件，除非用户明确授权。

### 2. 不硬编码凭证

安装脚本中不得硬编码 AK/SK、API Key 等凭证。SWR 镜像应设为公开访问，避免 `docker login`。如必须认证，通过环境变量或参数传入。

### 3. 不修改第三方源码

不得修改所部署开源项目的源代码。如需定制，通过配置文件、环境变量或 fork 后修改实现。

### 4. README 即文档

不要创建单独的指导文档文件（如 `xxx-guide.md`）。`README.md` 是唯一的文档。

### 5. 先确认再动手

开发前必须确认决策点（地域、语言、Docker vs 直装等），不得擅自假设。

### 6. OBS 命名规范

```
obs://{bucket}/{project}/
├── cn/
│   └── install_{app}.sh
├── hk/
│   └── install_{app}.sh
└── {project}-platform.zip
```

项目名不带后缀，cn/ 和 hk/ 子目录放脚本，归档包放根目录。

### 7. 模板和脚本分离

`.tf` 文件的 user_data 只做：改密码 → wget 下载脚本 → 执行 → 清理。所有部署逻辑在 `.sh` 脚本中。

## Recent Pitfalls (近期踩坑记录)

### Pitfall 19: Provider 块显式 auth_url 导致 IMS 认证失败

**现象：** RFS 部署报错 `error retrieving IMS images: Authentication failed`

**根因：** Provider 块显式指定了 `auth_url`、`cloud`、`insecure`，与 RFS 内部认证机制冲突。

**修复：** Provider 块只写 `region`，其他全部删掉。
```hcl
provider "huaweicloud" {
  region = "ap-southeast-1"
}
```

### Pitfall 20: Ubuntu 24.04 pip 安装被 PEP 668 阻止

**现象：** `pip3 install` 报错 `externally-managed-environment`

**根因：** Ubuntu 24.04 启用了 PEP 668，禁止 pip 系统级安装。

**修复：** 必须加 `--break-system-packages --ignore-installed`，不要用 fallback 命令（会被 `2>/dev/null` 吞掉错误）。
```bash
pip3 install headroom-ai fastapi uvicorn 'httpx[http2]' transformers \
  -i https://pypi.tuna.tsinghua.edu.cn/simple \
  --break-system-packages --ignore-installed
```

### Pitfall 21: 系统预装包导致 pip 安装失败

**现象：** `Cannot uninstall rich 13.7.1, RECORD file not found. Hint: The package was installed by debian.`

**根因：** Ubuntu 系统预装的 `rich` 包，pip 无法覆盖。

**修复：** 加 `--ignore-installed` 跳过已安装包检查。

### Pitfall 22: Terraform `%{...}` 被解析为模板指令

**现象：** `.tf` 文件中 curl 的 `%{http_code}` 报语法错误

**根因：** `%{...}` 是 Terraform 模板指令语法（`%{if}`, `%{for}`），在 heredoc 中也会被解析。

**修复：** 转义为 `%%{http_code}`。

### Pitfall 23: 环境变量未注入到进程

**现象：** `settings.json` 配置正确，但 Claude Code 不走代理

**根因：** CLI 工具从进程环境读取环境变量，`settings.json` 的 `env` 配置不一定被所有版本读取。

**修复：** 环境变量必须通过 `.bashrc` 的 `export` 注入，并 `source /root/.bashrc` 生效。

### Pitfall 24: docker-compose 挂载的配置文件缺失

**现象：** 容器报 `Failed to find configuration file`

**根因：** docker-compose.yml 通过 volume 挂载了配置文件（如 `./project/.../config.js`），但安装脚本只下载了 compose 文件，没下载配置。

**修复：** 用 `git clone --depth 1` 克隆整个仓库，而不是单独下载文件。

### Pitfall 25: Headroom 代理上游未指向 MaaS

**现象：** 代理运行正常但 stats 显示 0 压缩，请求没到达 MaaS

**根因：** Headroom 代理默认转发到 `api.anthropic.com`，需要 `ANTHROPIC_TARGET_API_URL` 指向 MaaS。

**修复：**
```bash
export ANTHROPIC_TARGET_API_URL=https://api.modelarts-maas.com/anthropic
headroom proxy --host 0.0.0.0 --port 8787
```

### Pitfall 26: Headroom 不压缩对话消息

**现象：** stats 显示 `no_compressible_content`，tokens_saved 为 0

**根因：** Headroom 硬编码保护 user/system/assistant 消息，只压缩 tool 输出。简单对话没有可压缩内容。

**修复：** 这是设计限制，不是配置问题。Headroom 适合工具密集型会话（大量 bash 输出、文件读取），简单聊天效果有限。

### Pitfall 27: SWR 镜像拉取需要认证

**现象：** `error from registry: You may not login yet - there is no X-Auth-Token`

**根因：** SWR 镜像未设为公开，需要 `docker login` 认证。

**修复：** 在 SWR 控制台把镜像设为公开，避免在脚本中硬编码凭证。

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

**CRITICAL: Only specify `region`.** Do NOT add `auth_url`, `cloud`, or `insecure` — RFS auto-derives them. Explicit values cause IMS authentication errors.

**JSON format:**
```json
"terraform": {
    "required_providers": {
        "huaweicloud": {
            "source": "huawei.com/provider/huaweicloud",
            "version": ">= 1.20.0"
        }
    }
},
"provider": {
    "huaweicloud": {
        "region": "cn-north-4"
    }
}
```

**HCL format:**
```hcl
terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.20.0"
    }
  }
}

provider "huaweicloud" {
  region = "ap-southeast-1"
}
```

**Common regions:**
| Region | Code | Type |
|--------|------|------|
| Beijing | cn-north-4 | Domestic |
| Guangzhou | cn-south-1 | Domestic |
| Shanghai | cn-east-3 | Domestic |
| Hong Kong | ap-southeast-1 | Overseas |
| Singapore | ap-southeast-3 | Overseas |
| Bangkok | ap-southeast-2 | Overseas |

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
            "name": "Ubuntu 24.04 server 64bit",
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

### Pitfall 12: Rust/Go Binary GLIBC Version Mismatch

**Symptom:** Pre-compiled binary (Rust, Go, or Zig) downloads and extracts successfully but fails to run with:
```
/lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.38' not found
```

**Root cause:** Pre-compiled binaries are often built against a newer GLIBC (e.g. 2.38/2.39 on modern CI runners), but the default Huawei Cloud ECS image (Ubuntu 22.04) ships GLIBC 2.35. Rust binaries using `tokio`, `reqwest`, or other modern crates commonly require GLIBC >= 2.38. Go binaries built with Go 1.22+ may also exhibit similar issues with `__clock_gettime` or `pthread` symbols.

**Fix:** Choose the highest Ubuntu LTS image available:

```json
"data": {
    "huaweicloud_images_image": {
        "Ubuntu": {
            "most_recent": true,
            "name": "Ubuntu 24.04 server 64bit",
            "visibility": "public"
        }
    }
}
```

**For lower-version OS requirements** (e.g. CentOS 7 with GLIBC 2.17):
- Option A: Build the binary on the same or older OS using `cargo build --target x86_64-unknown-linux-musl` for fully static musl builds (no GLIBC dependency)
- Option B: Use Docker with `FROM alpine:3.19` and static musl compilation
- Option C: Include source compilation as fallback in the install script (download `{app}-src.tar.gz` from OBS, `cargo build --release`)

**General rule:** Always default to the **latest** Ubuntu LTS image for ECS. Only downgrade if the application explicitly requires an older OS.

### Pitfall 13: Empty Protocol String in Security Group Rules is Invalid

**Symptom:** RFS deploys successfully but the security group rule for "all ports" doesn't appear, or RFS returns an error like:
```
error: Invalid value for parameter 'protocol'
```

**Root cause:** Using `"protocol": ""` (empty string) intending to mean "all protocols" — this is an invalid value. The `huaweicloud_networking_secgroup_rule` resource does not accept an empty string for `protocol`.

**Fix:** To allow all ports from a specific IP, create separate TCP and UDP rules — or use `"tcp"` with a wide port range:
```json
"test_ip_tcp": {
    "protocol": "tcp",
    "ports": "1-65535",
    "remote_ip_prefix": "x.x.x.x/32"
},
"test_ip_udp": {
    "protocol": "udp",
    "ports": "1-65535",
    "remote_ip_prefix": "x.x.x.x/32"
}
```

For cases where only SSH + application access is needed, just open the specific TCP ports:
```json
"remote_access": {
    "protocol": "tcp",
    "ports": "22,80,443,8080",
    "remote_ip_prefix": "x.x.x.x/32"
}
```

### Pitfall 14: SWR Mirror Is Not a Universal Docker Hub Proxy

**Symptom:** Docker pull fails with `400 Bad Request` from SWR mirror for images like `supabase/studio`, even though other images like `kong` or `postgres` work fine.

**Root cause:** A project-level SWR mirror (`{project-hash}.mirror.swr.myhuaweicloud.com`) only caches images that have been explicitly pulled through it before. It is not a full Docker Hub proxy cache. Images that have never been pulled through the mirror return 400, and Docker treats 400 as definitive — it **does not fall back** to the second mirror in `registry-mirrors`.

**Fix — Option A (Recommended for production):** Push all required images to SWR and reference them directly in compose files. This avoids mirror dependency entirely and pulls from Huawei Cloud internal network at maximum speed.

**Fix — Option B (Quick start):** For small deployments, use a reliable domestic mirror like `docker.1ms.run` as the primary source, with explicit tag-and-retry logic in the install script (not relying solely on daemon.json mirror fallback).

### Pitfall 15: Reserved PostgreSQL Roles Require Superuser

**Symptom:** After deployment, service containers keep restarting with `password authentication failed for user "xxx"`. Running `ALTER USER` as `postgres` fails with `"xxx" is a reserved role, only superusers can modify it`.

**Root cause:** Some PostgreSQL images create reserved roles during initialization. The default `postgres` user is NOT a superuser in these images — a separate admin role (e.g. `supabase_admin`) has the actual superuser privileges.

**Fix:** Identify and use the actual superuser:
```bash
# Find superuser roles
docker exec db psql -U postgres -c "SELECT rolname, rolsuper FROM pg_roles;"

# Then authenticate as the real superuser
docker exec -e PGPASSWORD=$PWD db \
  psql -U supabase_admin -h localhost -d postgres \
  -c "ALTER USER authenticator WITH PASSWORD '$PWD';"
```

**Always include a post-deploy DB init stage** that waits for PG to be healthy, checks if service roles have passwords set, and fixes them if not.

### Pitfall 16: Missing Env Vars Cause Silent Container Restart Loops

**Symptom:** Containers start and immediately restart in a loop. No obvious error in `docker ps`. Each restart cycle gets faster.

**Root cause:** Docker Compose services exit immediately when required env vars are missing. With `restart: unless-stopped`, Docker restarts them infinitely.

**Common missing variables:**

| Service | Missing Var | Error |
|---------|-------------|-------|
| GoTrue | `API_EXTERNAL_URL` | `required key ... missing value` |
| Realtime | `SECRET_KEY_BASE` / `APP_NAME` | `APP_NAME not available` |
| Supavisor | `SECRET_KEY_BASE` | `environment variable ... missing` |
| Storage | `FILE_STORAGE_BACKEND_PATH` | `env variable not set` |

**Fix:** Generate `.env` dynamically with `openssl rand` for secrets. After `docker compose up`, check container logs for `fatal`/`error` messages. Add missing schemas (`CREATE SCHEMA IF NOT EXISTS`) in a bootstrap step.

### Pitfall 17: Empty Volume Mount Overrides Built-in Init Scripts

**Symptom:** Database starts clean but custom roles, schemas, and extensions that should be pre-installed by the image are missing.

**Root cause:** Mounting a host volume at `/docker-entrypoint-initdb.d` **replaces** the entire directory, including any init scripts baked into the image. An empty host directory effectively disables all built-in database initialization.

```yaml
# ❌ BAD: empty host dir overwrites image's built-in init scripts
volumes:
  - ./volumes/db/init:/docker-entrypoint-initdb.d:ro

# ✅ GOOD: only mount data directory
volumes:
  - ./volumes/db/data:/var/lib/postgresql/data
```

**Rule:** Never mount an empty directory to `/docker-entrypoint-initdb.d`. If you need custom init scripts alongside the image's built-in ones, copy them into the directory before Docker starts, or use a custom Dockerfile.

### Pitfall 18: Supabase/RDS Hybrid Architecture Is Not Feasible

**Symptom:** Trying to replace Supabase's bundled PostgreSQL with managed RDS fails — missing extensions, authentication errors, broken realtime subscriptions.

**Root cause:** Supabase's `supabase/postgres` image is heavily customized with C extensions (`pgsodium`, `pg_graphql`, `pg_net`, `pgmq`), reserved roles, custom postgresql.conf settings, and replication slots — none of which are available on standard managed RDS.

**Decision framework:**

```
Is the app's PostgreSQL a vanilla postgres (no custom extensions/init scripts)?
  ├─ YES → RDS viable, preferred for production
  │   Examples: n8n, LiteLLM, Airbyte, Metabase
  └─ NO → Custom extensions/reserved roles/special config
      ├─ Want managed DB? → Second ECS running the custom PG image
      └─ Accept bundled PG? → Single ECS with Docker Compose
      Examples: Supabase, GitLab
```

---

## Hard Rules (Always Apply)

These rules are non-negotiable and apply to all solutions:

### Rule 1: Provider Block — Region Only

```hcl
provider "huaweicloud" {
  region = "cn-north-4"   # or "ap-southeast-1", etc.
}
```

Never add `auth_url`, `cloud`, `insecure`. RFS auto-derives them. Explicit values cause `error retrieving IMS images: Authentication failed`.

### Rule 2: Resource Names — Always Add Random Suffix

```hcl
locals {
  name_suffix = substr(uuid(), 0, 8)
}

resource "huaweicloud_vpc" "vpc" {
  name = "${var.solution_name}-${local.name_suffix}-vpc"
  ...
}
```

Apply `-${local.name_suffix}` to ALL resource names (VPC, subnet, secgroup, EIP, ECS, bandwidth). Prevents conflicts when multiple customers deploy the same solution.

### Rule 3: Template-Script Separation

- `.tf` file: minimal user_data (password + wget + execute + cleanup)
- `.sh` file: all deployment logic (install, configure, start)
- Never embed long scripts in user_data heredoc

### Rule 4: pip Install — Always Use These Flags

```bash
pip3 install {package} --break-system-packages --ignore-installed
```

Ubuntu 24.04 PEP 668 blocks system-wide pip installs. `--ignore-installed` prevents conflicts with system packages (e.g., `rich`). No fallback commands — they get silently swallowed by `2>/dev/null`.

### Rule 5: Dependencies — Install Completely in One Command

```bash
pip3 install headroom-ai fastapi uvicorn 'httpx[http2]' transformers \
  -i https://pypi.tuna.tsinghua.edu.cn/simple \
  --break-system-packages --ignore-installed
```

Never split across multiple commands. Missing one dependency causes runtime failures that are hard to diagnose.

### Rule 6: Environment Variables — Export in .bashrc

```bash
cat >> /root/.bashrc << 'EOF'
export ANTHROPIC_BASE_URL="http://localhost:8787"
export ANTHROPIC_TARGET_API_URL="https://api.modelarts-maas.com/anthropic"
export ANTHROPIC_MODEL="deepseek-v3.2"
EOF
source /root/.bashrc
```

Environment variables must be in the process environment (`.bashrc` export), not just in `settings.json`. CLI tools read from process env, not config files.

### Rule 7: README Is the Documentation

Do NOT create separate guide files (`xxx-guide.md`). The `README.md` is the single source of truth. Follow the 9-section Hermes format (Decision 6).

### Rule 8: No Docker for Non-Docker Apps

If the application is a CLI tool or Python package (not a containerized service), install directly via pip/npm. Don't wrap in Docker unnecessarily.

---

## Decision Points (User-Confirmed Patterns)

The following decisions are confirmed by the user and should be applied consistently across all future solutions. **Do not assume — ask the user to confirm before applying.**

### Decision 1: Template Format — HCL (.tf) vs JSON (.tf.json)

| Format | Pros | Cons |
|--------|------|------|
| `.tf` (HCL) | Clean syntax, heredoc support, readable, native Terraform format | RFS may require JSON for some operations |
| `.tf.json` (JSON) | RFS native, no HCL parsing needed | Verbose, no heredoc, hard to maintain multiline user_data |

**Default:** Ask the user. HCL preferred for new projects unless RFS requires JSON.

### Decision 2: Install Script — Inline user_data vs OBS Download

| Strategy | Pros | Cons |
|----------|------|------|
| **Inline user_data** | Single file deployment, no OBS dependency, simpler pipeline | user_data grows large, harder to iterate independently |
| **OBS download** | Hot-fixable without RFS template change, script is independently versioned | Requires OBS bucket, extra wget step, two files to maintain |

**Default:** Ask the user. Inline is cleaner for simple deployments; OBS download is better for complex scripts that need frequent iteration.

### Decision 3: Region — Domestic vs Overseas

| Region Type | Docker Source | SWR Needed? | Mirror Config |
|-------------|--------------|-------------|---------------|
| **Domestic (cn-*)** | SWR mirror or Huawei Cloud mirror | Yes — `mirrors.huaweicloud.com` is project-level, not universal | `daemon.json` registry-mirrors + fallback |
| **Overseas (ap-*, eu-*)** | Direct from source (Docker Hub, ghcr.io) | No — global access is fast enough | None needed |

**Default:** Domestic → use SWR acceleration pattern (Pitfall 14). Overseas → pull directly from source registries, no SWR login needed.

**Rationale:** Domestic ECS has poor connectivity to Docker Hub / ghcr.io. SWR mirror is project-scoped (not a universal proxy), so images must be pre-pushed to SWR. Overseas ECS has direct global access, making SWR unnecessary overhead.

### Decision 4: Language — Chinese vs English

| Target Audience | Description Language | Variable Descriptions | Output Messages |
|-----------------|---------------------|----------------------|-----------------|
| Domestic (cn-* regions) | Chinese | Chinese | Chinese |
| Overseas (ap-*, eu-* regions) | English | English | English |

**Default:** Match the region. Domestic → Chinese. Overseas → all English.

### Decision 5: Script Architecture — Separate vs Inline for user_data

When using **inline user_data** (Decision 2):
- All config files (docker-compose.yaml, config.yaml, etc.) are generated via heredoc inside user_data
- No files need to be pre-uploaded to OBS
- The .tf file is completely self-contained

When using **OBS download** (Decision 2):
- user_data only downloads and executes the install script
- Config files are uploaded to OBS separately
- Install script + config files are versioned independently on OBS

### Decision 6: Deployment Documentation — Required for Every Project

Every solution practice **must** include a `README.md` deployment guide. The language follows Decision 4 (domestic → Chinese, overseas → English).

**Required sections:**

| Section | Content |
|---------|---------|
| Title | `# Solution Name — Tagline 一键部署` (Chinese) / `# Solution Name — Tagline One-Click Deployment` (English) |
| 方案概述 / Solution Overview | What the software is, how it deploys on Huawei Cloud |
| 方案架构 / Architecture | ASCII art diagram + resource table (type, spec, qty, description) |
| 适用场景 / Use Cases | 3-5 bullet points |
| 方案优势 / Key Benefits | 4-6 bullet points with bold keywords |
| 部署指南 / Deployment Guide | Prerequisites, one-click deploy steps, parameter table |
| 开始使用 / Getting Started | Access URLs, SSH commands, API call examples, config instructions |
| 预估费用 / Estimated Cost | Per-resource cost table (hourly + monthly) with total |
| 快速卸载 / Quick Uninstall | RFS console delete steps |
| 更多资源 / More Resources | GitHub, upstream docs, Huawei Cloud RFS docs |

**Two-tier model:**
- `README.md` (required): Full deployment guide in the project root or `tf/` directory
- `docs/overview.md` (optional): Short marketing summary (~30 lines)

### Decision 7: OBS Naming Convention — Project Directory & Archive Name

**OBS 目录结构（统一规范）：**

```
obs://{bucket}/{project}/
├── cn/
│   └── install_{app}.sh          ← 国内版安装脚本
├── hk/
│   └── install_{app}.sh          ← 海外版安装脚本
└── {project}-platform.zip        ← 完整归档包（含 cn/ + hk/）
```

**规则：**
- 项目名不带后缀：`aitoearn`、`litellm`、`headroom-claude-code`
- `cn/` 和 `hk/` 子目录放各自的安装脚本
- `{project}-platform.zip` 放在项目根目录，包含 cn/ + hk/ 全部文件
- 模板里的 `user_data` 按区域指向对应子目录：`.../aitoearn/cn/install_aitoearn.sh`

**本地目录结构：**
```
practices/{project}/
├── cn/
│   ├── deploying-{project}.tf
│   ├── scripts/install_{app}.sh
│   ├── .extension
│   └── README.md
└── hk/
    ├── deploying-{project}.tf
    ├── scripts/install_{app}.sh
    ├── .extension
    └── README.md
```

### Decision 8: Docker vs Direct Install

| Approach | When to Use |
|----------|-------------|
| **Docker Compose** | Multi-container apps (DB + app + monitoring), apps with official Docker images |
| **Direct install (pip/npm)** | CLI tools, single-process apps, Python/Node packages |

**Default:** Ask the user. Don't default to Docker if the app is a simple CLI tool.

### Decision 9: Upstream API Configuration

When a proxy tool (like Headroom) forwards to an upstream API, the upstream URL must be explicitly configured:

```bash
# Environment variable for proxy upstream
export ANTHROPIC_TARGET_API_URL=https://api.modelarts-maas.com/anthropic
```

**Always verify** the proxy's routing table in startup logs to confirm upstream is correct:
```
/v1/messages → https://api.modelarts-maas.com/anthropic  ✅
/v1/messages → https://api.anthropic.com                  ❌ (wrong upstream)
```

### Decision 10: Word Document Generation

Every solution should include a `.docx` version of the README for offline viewing:
- CN: `Headroom-ClaudeCode-部署指南.docx`
- HK: `Headroom-ClaudeCode-Deployment-Guide.docx`
- Generated from README.md using `python-docx`
- Uploaded alongside README to OBS

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
1. `install_{app}.sh` — the 4-stage deployment script (if using OBS download pattern)
2. `deploying-{app}.tf` or `.tf.json` — the RFS template
3. `{app}[-hk|-platform].zip` — project archive (naming per Decision 7)

---

## Validation Checklist

Before deploying, verify:

**Template:**
- [ ] `required_providers` is an object, not array
- [ ] Only `huaweicloud` provider listed (no `random`, `tls`, etc.)
- [ ] Provider block has ONLY `region` — no `auth_url`, `cloud`, `insecure`
- [ ] `locals { name_suffix = substr(uuid(), 0, 8) }` present
- [ ] ALL resource names include `-${local.name_suffix}`
- [ ] user_data is minimal: password + wget + execute + cleanup

**Install Script:**
- [ ] pip install uses `--break-system-packages --ignore-installed`
- [ ] All dependencies in ONE pip install command
- [ ] **Domestic:** PyPI mirror `-i https://pypi.tuna.tsinghua.edu.cn/simple`
- [ ] **Domestic (cn-\*):** Docker CE from `mirrors.huaweicloud.com`; **Overseas:** Docker CE from `download.docker.com`
- [ ] **Domestic:** `docker login` to SWR + images pre-pushed; **Overseas:** Direct pull from source
- [ ] Environment variables exported in `.bashrc`, not just in settings.json
- [ ] Proxy upstream URL explicitly set (e.g., `ANTHROPIC_TARGET_API_URL`)

**Documentation:**
- [ ] README.md follows 9-section Hermes format
- [ ] Word document (.docx) generated from README
- [ ] **Domestic:** Descriptions in Chinese; **Overseas:** All descriptions in English
- [ ] Output section references correct log path

**OBS Upload:**
- [ ] Install script uploaded: `obs://{bucket}/{project}[-hk]/install_{app}.sh`
- [ ] Platform zip uploaded: `obs://{bucket}/{project}[-hk]/{project}[-hk]-platform.zip`
- [ ] Word doc uploaded alongside README

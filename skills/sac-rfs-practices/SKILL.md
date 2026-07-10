---
name: sac-rfs-practices
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
metadata:
  status: formal
  scope: formal-delivery
  owner: project
---

# Huawei Cloud RFS Solution Builder

Build production-ready Huawei Cloud RFS (Resource Formation Service) solution templates.
Follow standards from `assets/demo/` reference projects plus accumulated field-tested fixes.

## 定位

本 skill 是 **开发 Agent（sac-developer）** 的核心技术规范（Terraform 模板 + Shell 脚本 + Docker Compose），也可被 **测试 Agent（sac-tester）** 和 **安全 Agent（sac-security）** 加载用于验证参考。多 Agent 协作流程参见 `.claude/MULTI-AGENT-README.md`。

### 单 Agent 模式（手动调用）

When asked to create or fix a Huawei Cloud RFS solution directly:

1. **Confirm decision points** (see Decision Points section below) — ask user for non-default choices
2. **Write the .tf template**: Variables → data sources → VPC/subnet/secgroup → EIP → ECS with the selected user_data mode
3. **Write the install script**: Independent `.sh` file with all deployment logic
4. **Write documentation**: Two Markdown docs per site-level directory structure
5. **Upload to OBS**: Template + script + docs, naming per Decision 7
6. **Test with RFS**: Deploy, SSH in, verify services

### user_data Strategy Rule

Two user_data modes are valid. Pick one explicitly in the decision points and keep it consistent for a practice/variant.

#### Mode A: OBS script bootstrap

The `.tf` file's `user_data` is minimal — only:
1. Reset ECS password
2. Download install script from OBS
3. Execute the script
4. Clean up

```hcl
user_data = "#!/bin/bash\necho 'root:${var.ecs_password}' | chpasswd\nwget -P /home/ https://{bucket}.obs.{region}.myhuaweicloud.com/{project}/install_{app}.sh\nbash /home/install_{app}.sh\nrm -rf /home/install_{app}.sh"
```

This mode is now an exception path. Use it only when the user explicitly asks for external scripts or when a specific delivery constraint requires hot-fixable OBS-hosted scripts.

#### Mode B: inline user_data

The `.tf` file is self-contained and writes configuration files via heredoc before starting services.

This is the SAC standard mode. Follow the LiteLLM/Supabase pattern: Terraform template contains infrastructure resources plus inline deployment logic, including package installation, configuration generation, service startup, health checks, and final outputs. `scripts/` is not a required delivery directory for standard RFS practices.

Inline user_data must remain readable and auditable:
- split logic into clear shell sections;
- use heredoc for generated compose/config files;
- keep health checks and final access information in the template;
- avoid external OBS script dependencies unless the user explicitly approves an exception.

Do not mix Mode A and Mode B in the same deployable instance.

## Development Workflow (SAC 标准流程)

参见 `sac-project-rules` Section 8（SAC 交付流程）获取完整阶段定义。

### 阶段详解

| 阶段 | 负责人 | 产出 |
|------|--------|------|
| 5. 开发 | AI | 内联 user_data 的 .tf 模板 + Markdown 文档（部署指南+方案详情） |
| 6. 测试 OBS 上传 | AI | 上传到测试桶（桶名见本地开发记忆），用户验证 |
| 8. 生产打包 | AI | 整理最终归档包，预置生产 OBS 路径的模板 |

### OBS 桶规范

参见 `skills/reference/obs-conventions.md`（OBS 目录结构、环境区分、RFS URL 格式、上传操作）。

### 最终交付物

每个方案最终交付：
1. **RFS 页面 URL** — 预置好模板和参数，用户点击即可部署
2. **归档包** — `{project}.zip`，包含 cn/ + intl/ 全部区域
3. **Terraform 模板** — 测试候选为 `deploying-{project}_vN.tf`，用户确认后提升为 `deploying-{project}.tf` 正式入口；部署逻辑默认内联在 user_data 中
4. **文档双件套** — 部署指南 + 方案详情（中文内容 `_zh`，英文内容 `_en`）

`manifest.json` 不是 SAC 标准交付物。只有用户明确要求、测试桶临时索引、或外部自动化工具需要时，才可作为辅助文件生成，不得写入标准交付清单。

### Terraform 候选与正式入口

对新建或修改中的模板使用以下流程：

1. 在目标 deployable instance 的 `terraform/` 下创建 `deploying-{solution}_v1.tf`；后续修改递增为 `_v2`、`_v3`。
2. 保持候选文件不可变；不得原地覆盖已经实际测试的 `_vN`。
3. 上传测试桶时使用带修订号候选，并记录对应 SAC 四级测试版本。
4. 每次产生新修订后，向用户确认实际云上测试结果。
5. 只有用户明确确认通过后，才把候选的相同内容复制为 `deploying-{solution}.tf` 正式入口并更新生产发布对象。
6. 保留候选文件用于审计与回滚。历史无版本模板在下一次修改时开始渐进迁移，不批量破坏现有链接。

模板版本、项目版本和发布门禁的完整规则以 `sac-project-rules` Section 13 为准。

## User Constraints (用户约束)

以下约束必须遵守，不可违反：

### 1. reference/ 目录只读

`solution-practices/reference/` 目录仅用户可修改。AI 不得主动修改此目录下的任何文件，除非用户明确授权。

### 2. 不硬编码凭证

内联 user_data、可选安装脚本和配置文件中均不得硬编码 AK/SK、API Key 等凭证。SWR 镜像应设为公开访问，避免 `docker login`。如必须认证，通过环境变量或参数传入。

### 3. 不修改第三方源码

不得修改所部署开源项目的源代码。如需定制，通过配置文件、环境变量或 fork 后修改实现。

### 4. 文档交付规范

正式交付文档为 Markdown 格式（.md），按站点归类，固定为部署指南 + 方案详情两类：
- **中国站中文** → `cn/docs/{Name}-部署指南_zh.md` + `cn/docs/{Name}-方案详情_zh.md`
- **国际站中文** → `intl/docs/zh-cn/{Name}-部署指南_zh.md` + `intl/docs/zh-cn/{Name}-方案详情_zh.md`
- **国际站英文** → `intl/docs/en-us/{Name}-Deployment-Guide_en.md` + `intl/docs/en-us/{Name}-Solution-Details_en.md`
- 高可用与标准版合并为一篇文档，在"快速部署"章节按子章节区分

文件名语言后缀必须跟随文档正文语言，而不是站点目录名：中文正文统一 `_zh`，英文正文统一 `_en`。

### 5. 先确认再动手

开发前必须确认决策点（地域、语言、Docker vs 直装等），不得擅自假设。

### 6. OBS 命名规范

参见 `skills/reference/obs-conventions.md`。

### 7. user_data 策略

标准模式为全内联 user_data：
- `.tf` 自包含基础设施和应用部署逻辑；
- 参考 LiteLLM、Supabase 这类实践，不做分布式脚本；
- `scripts/` 不是标准交付目录，除非用户明确要求或存在必须外置脚本的技术约束。

OBS 下载脚本仅作为例外模式：`.tf` 的 user_data 只做改密码、下载脚本、执行、清理；所有部署逻辑在 `.sh` 脚本中。启用前必须说明原因并获得用户确认。

同一个 deployable instance 不得混用两种模式。

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

**Common regions:** 参见 `skills/reference/region-mapping.md`

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

### Resource Naming

Use `var.solution_name` directly as the resource name prefix. Each RFS deployment creates an independent resource stack with its own state:

```json
"name": "${var.solution_name}-vpc"
"name": "${var.solution_name}-subnet"
"name": "${var.solution_name}-sg"
"name": "${var.solution_name}-ecs"
```

If a practice needs collision avoidance beyond `solution_name`, derive names from stable user input only. Do not generate changing names during plan/apply.

**WARNING:** Do NOT use `substr(uuid(), 0, 8)` in locals. The `uuid()` function generates a new value on every `plan`/`apply`, causing ALL resources with that suffix to be **destroyed and recreated** on every deployment. This breaks idempotency and causes data loss.

Also avoid `random_id` resource — the `random` provider is not available in Huawei Cloud RFS.

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
        "name": "${var.solution_name}-vpc",
        "cidr": "172.16.0.0/16"
    }
},
"huaweicloud_vpc_subnet": {
    "subnet": {
        "name": "${var.solution_name}-subnet",
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
        "name": "${var.solution_name}-ecs",
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

### user_data Pattern

Mode A keeps user_data to an absolute minimum. Only reset password + download + execute:

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

**Fix:** For cn sites, keep Docker Hub image names unchanged in compose/install scripts and configure Docker daemon with the approved domestic registry mirror:
```json
{
  "registry-mirrors": ["https://docker.wangzhou3.top"]
}
```

Do not rewrite Docker Hub image references to custom `docker.wangzhou3.top/<project>/...` paths unless those exact tags are a verified formal image repository.

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

**Fix:** Use `var.solution_name` directly as the name prefix. Each RFS deployment is an independent stack, so unique suffixes are not needed. Do NOT use `uuid()` — it breaks idempotency.

### Pitfall 9: VPC/ECS Name Conflicts  

**Symptom:** Can't deploy a second instance due to name collisions.

**Fix:** Use `var.solution_name` consistently as the resource name prefix. If multiple deployments must coexist under one account, require the user to provide a distinct `solution_name`; do not append `uuid()` or `random` values.

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

### Pitfall 28: Proxy Registry Is Not a Project Image Repository

**Symptom:** `docker compose pull` fails with `not found` for images rewritten to paths like `docker.wangzhou3.top/sac/supabase-image/supabase-gotrue:v2.186.0`, and no containers listen on the application port.

**Root cause:** `docker.wangzhou3.top` is a Docker Hub proxy/accelerator, not a guarantee that arbitrary project-specific image paths and tags exist. Rewriting official Docker Hub images into custom `sac/...` paths makes Docker query non-existent repositories.

**Fix:** Keep official Docker Hub image names in compose files, for example `supabase/gotrue:v2.186.0`, `kong:3.9.1`, `postgrest/postgrest:v14.8`. Configure `/etc/docker/daemon.json` with `registry-mirrors: ["https://docker.wangzhou3.top"]` for cn sites. Only use fully qualified custom registry paths when the repository and exact tag have been pre-pushed and verified.

### Pitfall 29: Do Not Escape Shell Command Substitution in Terraform user_data

**Symptom:** Cloud-init reaches a shell loop or assignment and fails with `syntax error near unexpected token '('`; later containers restart because follow-up initialization never ran.

**Root cause:** In Terraform heredoc user_data, shell command substitution `$()` was written as `$$()`. Terraform only needs escaping for literal `${...}` interpolation via `$${...}`. `$(` is not Terraform interpolation and must remain unchanged.

**Fix:** Use `$(seq 1 30)` and `VAR=$(command ...)` in shell scripts. Use `$${POSTGRES_PASSWORD}` only when a generated compose file needs a literal `${POSTGRES_PASSWORD}` for Docker Compose variable expansion.

### Pitfall 30: Stateful Compose Apps Need Complete DB Bootstrap

**Symptom:** The gateway/dashboard is reachable, but Auth/Storage/Realtime containers restart or return 503. Logs show `database "supabase" does not exist`, `permission denied for database supabase`, or `no schema has been selected to create in`.

**Root cause:** The DB bootstrap only set a subset of service role passwords or created the database with the wrong owner. Supabase-style images also require service schemas (`auth`, `storage`, `_realtime`, `extensions`) with matching owners/search paths. When running SQL through a shell heredoc, `docker exec` without `-i` silently does not pass the SQL into the container.

**Fix:** Make DB bootstrap idempotent and complete: set the admin role password, create the application database with the real admin owner, alter existing DB owner if needed, create service schemas with correct authorization, grant database/schema privileges, then set all service role passwords. Use `docker exec -i ... psql <<SQL` for heredoc SQL and `-v ON_ERROR_STOP=1` so failed SQL stops cloud-init.

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

### Rule 2: Resource Names — Stable and Idempotent

```hcl
resource "huaweicloud_vpc" "vpc" {
  name = "${var.solution_name}-vpc"
  ...
}
```

Each RFS deployment is an independent resource stack. Use `var.solution_name` as prefix. If additional disambiguation is required, it must come from stable user input, not from `uuid()` or the unavailable `random` provider.

### Rule 3: user_data Mode Must Be Explicit

- Standard Mode inline: `.tf` is self-contained and contains install/config/start/health-check logic in user_data.
- Exception Mode OBS bootstrap: `.tf` contains minimal user_data; `.sh` contains install/config/start logic. Use only after user approval or explicit delivery constraints.
- Do not mix OBS bootstrap and inline deployment logic in one deployable instance.

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

### Rule 7: Markdown Docs Are the Formal Delivery

Formal documentation is delivered as Markdown (.md) under site-level directories:
- **cn site**: `cn/docs/{Name}-部署指南_zh.md` + `cn/docs/{Name}-方案详情_zh.md`
- **intl site zh-cn**: `intl/docs/zh-cn/{Name}-部署指南_zh.md` + `intl/docs/zh-cn/{Name}-方案详情_zh.md`
- **intl site en-us**: `intl/docs/en-us/{Name}-Deployment-Guide_en.md` + `intl/docs/en-us/{Name}-Solution-Details_en.md`
- HA and Standard content merged into one doc, differentiated at sub-section level under "快速部署"

### Rule 8: No Docker for Non-Docker Apps

If the application is a CLI tool or Python package (not a containerized service), install directly via pip/npm. Don't wrap in Docker unnecessarily.

### Rule 9: intl ECS Flavor — c7n Series Default, No x1 Validation

`practices/*/intl/` 下的 Terraform 模板：

- `ecs_flavor` 默认值使用 **`c7n.2xlarge.2`**，不使用 `x1` 系列（x1 为中国站专属性能实例，海外不一定存在）
- `ecs_flavor` 的 `validation` 正则**禁止仅匹配 `x1.*` 中国站专属性能实例**；允许匹配海外通用规格（如 `c7n.*`、`s6.*`）的宽松正则，或干脆不写 validation
- `description` 注明"请根据目标区域可用规格调整"

```hcl
# ✅ intl 模板正确写法
variable "ecs_flavor" {
  default     = "c7n.2xlarge.2"
  description = "ECS 规格，请根据目标区域可用规格调整"
}

# ❌ intl 模板禁止写法 — x1 系列海外不存在
variable "ecs_flavor" {
  default     = "x1.4u.8g"
  validation {
    condition     = can(regex("^x1\\.([1-9]|1[0-6])u\\.([1-9][0-9]{0,1}|1[0-2][0-8])g$", var.ecs_flavor))
    error_message = "..."
  }
}
```

---

## Decision Points (User-Confirmed Patterns)

The following decisions are confirmed by the user and should be applied consistently across all future solutions. **Do not assume — ask the user to confirm before applying.**

通用决策框架参见 `skills/reference/decision-framework.md`（Decision 1-6：模板格式、安装策略、地域、语言、脚本架构、Docker vs 直装）。

以下为 RFS 开发特有的决策点：

### Decision 7: OBS Naming Convention — Project Directory & Archive Name

参见 `skills/reference/obs-conventions.md`（OBS 目录结构、环境区分、RFS URL 格式、上传操作）。
本地 practices/ 和 release/ 目录结构定义参见 `sac-project-rules` Section 3-4。

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

### Decision 10: Document Generation — 3 Site-Level Versions

文档规范参见 `sac-project-rules` Section 3.2（目录结构 + 文档输出规范）和 `skills/reference/decision-framework.md`（Decision 6）。

---

## OBS Upload

参见 `skills/reference/obs-conventions.md`（OBS 目录结构、环境区分、上传操作）。

---

## Validation Checklist

验证清单参见各 Agent 配置（`sac-tester.json` 含模板结构验证、`sac-security.json` 含安全审计规则）。

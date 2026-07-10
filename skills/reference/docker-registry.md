# Docker 镜像站规范（双策略：cn daemon 代理 / intl 官方源）

> 本文档是 SAC 项目的 Docker 镜像 registry 权威来源。各 Skill 通过引用本文档避免重复。
>
> **cn 站点**保留官方 Docker Hub 镜像名，并通过 Docker daemon `registry-mirrors` 走 `docker.wangzhou3.top` 代理；**intl 站点**直拉官方 Docker Hub / ghcr.io，不加任何前缀。

---

## cn 站点 — daemon registry mirror

**Docker Hub 镜像在 compose/install/user_data 中保留官方镜像名，不直接改写为 `docker.wangzhou3.top/...`。** 国内加速通过 Docker daemon mirror 完成。

```json
{ "registry-mirrors": ["https://docker.wangzhou3.top"] }
```

适用范围：**cn 站点全部 install 脚本、docker-compose、TF 内联 user_data 中的 Docker Hub 镜像**。

### cn 路径映射约定

| 原镜像 | cn compose/install/user_data 写法 |
|---|---|
| 裸 Docker Hub `postgres:16`、`kong:3.9.1` | `postgres:16`、`kong:3.9.1` |
| 带命名空间 `prom/prometheus`、`n8nio/n8n`、`supabase/gotrue` 等 | `prom/prometheus`、`n8nio/n8n`、`supabase/gotrue` |
| `ghcr.io/X` | 原样保留或改为明确可用的正式镜像仓，不能假定 `docker.wangzhou3.top` 可代理 ghcr.io |
| SWR `swr.*.myhuaweicloud.com/sac/X` | 原样保留，除非已确认目标仓库公开且可拉取 |

禁止把 Docker Hub 镜像改写到项目自定义路径，例如 `docker.wangzhou3.top/sac/supabase-image/supabase-gotrue:v2.186.0`。`docker.wangzhou3.top` 是代理站点，不是保证完整 tag 存在的项目镜像仓。

### cn daemon.json

```json
{ "registry-mirrors": ["https://docker.wangzhou3.top"] }
```

---

## intl 站点 — 官方源直拉

**intl（海外）站点直拉官方 Docker Hub / ghcr.io，不加任何镜像站前缀。**

```
docker pull <image>
```

适用范围：**intl 站点全部 install 脚本、docker-compose、TF 内联 user_data**。不要在 intl 加 `docker.wangzhou3.top` 前缀。

### intl 路径映射约定

| 原镜像 | intl 写法 |
|---|---|
| `ghcr.io/X` | `ghcr.io/X`（原样保留） |
| 裸 Docker Hub `postgres:16` | `postgres:16`（无前缀） |
| 带命名空间 `prom/prometheus`、`n8nio/n8n` | `prom/prometheus`、`n8nio/n8n`（无前缀） |
| LiteLLM | `ghcr.io/berriai/litellm:main-stable` |

### intl daemon.json

不配置 `registry-mirrors`。海外 ECS 网络可直连官方源，无需中转。

---

## 不动的部分

- **Docker CE apt 源**（`mirrors.huaweicloud.com/docker-ce`、`download.docker.com/linux/ubuntu`）是 apt 软件源，不是容器镜像代理，除非用户明确要求否则不改。
- **SWR 登录凭证**（`SWR_USERNAME` / `SWR_PASSWORD` / `docker login`）若仅用于认证、不参与镜像引用拼接，属冗余但不破坏部署，清理时删 login 块即可。

## 相关

- 镜像引用出现在 install 脚本里时，注意 heredoc 引用展开：`docker-compose.yaml` 里 `${POSTGRES_PASSWORD}` 是 compose 变量（要保留 `$`），而 install 脚本里 heredoc 不带引号会展开 shell 变量——按需用 `$$` 转义或单引号 heredoc。
- OBS 脚本分发规范见 [obs-conventions.md](obs-conventions.md)。

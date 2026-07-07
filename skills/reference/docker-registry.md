# Docker 镜像站规范（双策略：cn 镜像站 / intl 官方源）

> 本文档是 SAC 项目的 Docker 镜像 registry 权威来源。各 Skill 通过引用本文档避免重复。
>
> **cn 站点**走 `docker.wangzhou3.top` 镜像站中转；**intl 站点**直拉官方 Docker Hub / ghcr.io，不加任何前缀。

---

## cn 站点 — 统一镜像站

**所有 Docker 镜像统一通过中转站 `docker.wangzhou3.top` 拉取，直接 pull，不走 SWR / ghcr.io / docker.litellm.ai / Docker Hub 直拉。**

```
docker pull docker.wangzhou3.top/<image>
```

适用范围：**cn 站点全部 install 脚本、docker-compose、TF 内联 user_data、daemon.json registry-mirrors**。

### cn 路径映射约定

| 原镜像 | 统一写法 |
|---|---|
| SWR `swr.*.myhuaweicloud.com/sac/X` | `docker.wangzhou3.top/sac/X`（保留 sac/ 路径） |
| `ghcr.io/X` | `docker.wangzhou3.top/X` |
| `docker.litellm.ai/X` | `docker.wangzhou3.top/X` |
| `docker.openhands.dev/X` | `docker.wangzhou3.top/X` |
| 裸 Docker Hub `postgres:16` | `docker.wangzhou3.top/library/postgres:16` |
| 带命名空间 `prom/prometheus`、`n8nio/n8n`、`berriai/litellm` 等 | `docker.wangzhou3.top/<ns>/<img>` |

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

- **Docker CE apt 源**（`mirrors.huaweicloud.com/docker-ce`、`download.docker.com/linux/ubuntu`）是 apt 软件源，不是镜像站，除非用户明确要求否则不改。
- **SWR 登录凭证**（`SWR_USERNAME` / `SWR_PASSWORD` / `docker login`）若仅用于认证、不参与镜像引用拼接，属冗余但不破坏部署，清理时删 login 块即可。

## 相关

- 镜像引用出现在 install 脚本里时，注意 heredoc 引用展开：`docker-compose.yaml` 里 `${POSTGRES_PASSWORD}` 是 compose 变量（要保留 `$`），而 install 脚本里 heredoc 不带引号会展开 shell 变量——按需用 `$$` 转义或单引号 heredoc。
- OBS 脚本分发规范见 [obs-conventions.md](obs-conventions.md)。

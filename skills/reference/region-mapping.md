# 区域代码映射表（公共参考文档）

> 本文档是 SAC 项目区域代码的权威来源。各 Skill 通过引用本文档避免重复。

## 站点类型

| 站点 | 默认 Region | 说明 |
|------|------------|------|
| **cn**（中国站） | **cn-north-4**（华北-北京四） | 中国站默认北京四 |
| **intl**（国际站） | **ap-southeast-3**（亚太-新加坡） | 国际站默认新加坡 |

> ⚠️ **铁律：站点（site）→ 区域（region）两层模型，不可混淆。**
> 顶层只有两个站点：`cn` 和 `intl`。**自 2026-07-03 起，HK（香港，`ap-southeast-1`）从 cn 站点改归 intl 国际站**（与 `af-south-1`、`ap-southeast-3` 等同级）。cn 站点现仅剩 `cn-north-4`。
> 目录结构：
> - cn 站点：`practices/<practice>/cn/<region>/<standard|ha>/`
> - intl 站点：`practices/<practice>/intl/<en-us|zh-cn>/<region>/<standard|ha>/`（intl 在 region 之上多一层语言：`en-us` 英文注释模板、`zh-cn` 中文注释模板，内容仅注释语言不同）
> 禁止出现 `practices/<practice>/hk/` 这种把 hk 当站点的写法。

## Region 代码与显示名称映射

| 区域代码 | 显示名称 | 站点 |
|---------|---------|------|
| `cn-north-4` | 华北-北京四 | cn |
| `cn-southwest-2` | 西南-贵阳一 | cn |
| `ap-southeast-1` | 中国-香港 | intl |
| `ap-southeast-2` | 亚太-悉尼 | intl |
| `ap-southeast-3` | 亚太-新加坡 | intl |
| `ap-southeast-5` | 亚太-马尼拉 | intl |
| `af-north-1` | 北非-（af-north-1） | intl |
| `af-south-1` | 非洲-约翰内斯堡 | intl |
| `la-north-2` | 拉美-（la-north-2） | intl |
| `la-south-2` | 拉美-圣地亚哥 | intl |
| `sa-brazil-1` | 南美-圣保罗一 | intl |
| `tr-west-1` | 土耳其-（tr-west-1） | intl |

## 区域组划分

| 区域组 | 包含的区域 | 特点 |
|--------|-----------|------|
| `cn` | cn-north-4, cn-southwest-2 | 国内站点，中文文档，镜像站 `docker.wangzhou3.top` + 华为云 apt 源 |
| `intl` | ap-southeast-1, ap-southeast-2, ap-southeast-3, ap-southeast-5, af-north-1, af-south-1, la-north-2, la-south-2, sa-brazil-1, tr-west-1 | 国际站（含香港），`en-us`/`zh-cn` 语言层，官方 Docker Hub + 官方 apt 源 |

## 国内/海外差异

| 维度 | 国内 (cn 站点) | 海外 (intl 站点) |
|------|------------|-------------------------------|
| Docker 安装源 | `mirrors.huaweicloud.com/docker-ce` | `download.docker.com` |
| pip 镜像 | 清华 PyPI | 直连 pypi.org |
| Docker 镜像 | `docker.wangzhou3.top` 镜像站（`/library/`、`/<ns>/`） | 官方 Docker Hub / `ghcr.io`（无前缀） |
| LiteLLM 镜像 | `docker.wangzhou3.top/berriai/litellm:main-stable` | `ghcr.io/berriai/litellm:main-stable` |

> ℹ️ **user_data 风格（2026-07-03 起）**：litellm 的 cn 与 intl 模板均改为**全内联 user_data**（heredoc 生成 docker-compose/config/prometheus + `docker compose up`），不再走 OBS 拉脚本。其他实践是否仍走 OBS 分发见各自模板。

## OBS 脚本分发（user_data 引导）

RFS 模板的 `user_data` 在 ECS 首次开机时从 OBS 拉取安装脚本，实现"脚本与模板解耦"。

**链路**：终端用户点 RFS url → 控制台预填 TF 模板 → ECS 开机 `wget/curl ${obs_base_url}/<相对路径>/install_*.sh` → 部署。

**三条铁律：**

1. **`obs_base_url` 的 endpoint 必须与桶实际所属区域一致。** OBS 桶是区域资源，`cn-south-1` 的桶只能用 `obs.cn-south-1.myhuaweicloud.com` 访问；写成 `cn-north-4`/`ap-southeast-1` 等 endpoint 会 DNS 失败或 403。一个桶 → 一个 endpoint，不随 ECS 部署区域变。

2. **`user_data` 里的脚本相对路径必须与桶内实际对象 key 一致，含 `scripts/` 层。** 规范路径：
   ```
   ${obs_base_url}/<practice>/<site>/<region>/<standard|ha>/scripts/install_*.sh
   ```
   仓库结构是 `.../<standard|ha>/scripts/install_*.sh`，桶镜像仓库，所以模板里也要带 `scripts/`。禁止写成 `.../standard/install_*.sh`（漏 `scripts/`）或 `litellm-hk/install_*.sh`（hk 当站点遗留）。

3. **`obs_base_url` 必须用 `locals` 块，禁止用 `variable`。** `variable` 会在 RFS 控制台暴露成用户可填字段——这是内部实现细节，不能给用户看。用 `locals { obs_base_url = "..." }`，`user_data` 里引用 `${local.obs_base_url}`。`locals` 不进参数面，TF 也不报错。切换自测/正式桶只改 `locals` 里这一处值。

**自测 vs 正式**：切换桶只改 `obs_base_url` 默认值一处，不改 `user_data` 相对路径。自测桶私有，ECS 拉脚本需通过 IAM 委托或脚本对象设 public-read；正式桶脚本对象公开读。

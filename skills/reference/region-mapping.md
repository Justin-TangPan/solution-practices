# 区域代码映射表（公共参考文档）

> 本文档是 SAC 项目区域代码的权威来源。各 Skill 通过引用本文档避免重复。

## 站点类型

| 站点 | 默认 Region | 说明 |
|------|------------|------|
| **cn**（中国站） | **cn-north-4**（华北-北京四） | 中国站默认北京四 |
| **intl**（国际站） | **ap-southeast-3**（亚太-新加坡） | 国际站默认新加坡 |

## Region 代码与显示名称映射

| 区域代码 | 显示名称 | 站点 |
|---------|---------|------|
| `cn-north-4` | 华北-北京四 | cn |
| `cn-southwest-2` | 西南-贵阳一 | cn |
| `ap-southeast-1` | 中国-香港 | cn |
| `ap-southeast-3` | 亚太-新加坡 | intl |
| `ap-southeast-5` | 亚太-马尼拉 | intl |
| `af-south-1` | 非洲-约翰内斯堡 | intl |
| `la-south-2` | 拉美-圣地亚哥 | intl |

## 区域组划分

| 区域组 | 包含的区域 | 特点 |
|--------|-----------|------|
| `cn` | cn-north-4, cn-southwest-2 | 国内 Docker 镜像、PyPI 镜像、中文文档 |
| `hk` | ap-southeast-1 | 海外首批试点，英文文档 |
| `intl` | ap-southeast-3, ap-southeast-5, af-south-1, la-south-2 | 其他海外区域，英文文档 |

## 国内/海外差异

| 维度 | 国内 (cn-\*) | 海外 (ap-\*, af-\*, tr-\*, la-\*) |
|------|------------|-------------------------------|
| Docker 安装源 | `mirrors.huaweicloud.com` | `download.docker.com` |
| pip 镜像 | 清华 PyPI | 直连 pypi.org |
| Docker 镜像 | SWR + `docker.1ms.run` | 直接从 Docker Hub |

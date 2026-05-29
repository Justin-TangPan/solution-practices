---
name: extension-format
description: RFS .extension 文件格式参考 — 参数分组、多语义化 i18n、encryption 加密标记的完整语法
---

# RFS .extension 文件格式

## 概述

`.extension` 是 RFS 的扩展配置文件，用于增强用户在控制台部署时的填参体验。支持两个核心功能：

| 功能 | 说明 |
|------|------|
| `variables` | 参数预加载与分组展示 |
| `i18n` | 多语义化（国际化） |

## 完整语法

```json
{
  "variables": {
    "grouping": {
      "{group_key}": {
        "label": "{显示名称}",
        "description": "{分组描述}"
      }
    }
  },
  "i18n": {
    "zh-cn": {
      "variable": {
        "{variable_name}": {
          "description": "{中文描述}"
        }
      }
    },
    "en-us": {
      "variable": {
        "{variable_name}": {
          "description": "{English Description}"
        }
      }
    }
  }
}
```

## 字段说明

### grouping

| 字段 | 必选 | 说明 |
|------|------|------|
| `{group_key}` | 是 | 分组标识符，与 variables.tf 中 `metadata.group` 值对应 |
| `label` | 是 | 控制台显示的分组名称（2-5 字） |
| `description` | 否 | 分组描述 |

### i18n

| 字段 | 说明 |
|------|------|
| `zh-cn` | 中文语言包 |
| `en-us` | 英文语言包 |
| `variable.{name}.description` | 对应变量的多语言描述 |

## 完整示例

### .extension

```json
{
  "variables": {
    "grouping": {
      "network_config": {
        "label": "网络配置",
        "description": "配置虚拟私有云网络"
      },
      "ecs_config": {
        "label": "ECS 配置",
        "description": "配置云服务器规格与登录"
      },
      "rds_config": {
        "label": "数据库配置",
        "description": "配置 RDS 数据库参数"
      },
      "app_config": {
        "label": "应用配置",
        "description": "配置应用部署参数"
      }
    }
  },
  "i18n": {
    "zh-cn": {
      "variable": {
        "ecs_name": { "description": "弹性云服务器名称" },
        "ecs_password": { "description": "ECS 管理员登录密码" }
      }
    },
    "en-us": {
      "variable": {
        "ecs_name": { "description": "ECS instance name" },
        "ecs_password": { "description": "Administrator password for ECS" }
      }
    }
  }
}
```

### 对应的 variables.tf

```hcl
variable "ecs_name" {
  description = "ECS 实例名称"
  type        = string
  metadata {
    group = "ecs_config"
  }
}

variable "ecs_password" {
  description = "ECS 管理员密码"
  type        = string
  sensitive   = true
  metadata {
    group = "ecs_config"
  }
}

variable "vpc_name" {
  description = "VPC 名称"
  type        = string
  default     = "solution-vpc"
  metadata {
    group = "network_config"
  }
}
```

## 分组设计原则

1. **每个分组包含 3-6 个变量**，太少则无分组必要，太多则不够精细
2. **分组 label 用中文短词**：网络配置、计算配置、存储配置、数据库配置
3. **分组按部署顺序排列**：网络 → 计算 → 存储 → 数据库 → 应用
4. **敏感参数独立成组或标记**：可在分组 description 中注明安全注意事项

## 典型分组模式

| 分组 | 包含变量 | 说明 |
|------|---------|------|
| `basic_config` | region, prefix, charging_mode | 基础信息 |
| `network_config` | vpc_name, vpc_cidr, subnet_cidr, az | 网络规划 |
| `ecs_config` | ecs_name, ecs_flavor, image_id, ecs_password, key_pair | 服务器 |
| `rds_config` | rds_name, rds_flavor, rds_password, db_version | 数据库 |
| `app_config` | app_version, domain_name, admin_email | 应用参数 |

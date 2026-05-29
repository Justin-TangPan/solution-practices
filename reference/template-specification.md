---
name: template-specification
description: 华为云 RFS Terraform 模板规范 — 文件命名、打包约束、编码要求、主入口规则
---

# RFS Terraform 模板规范

## 1. 模板文件要求

### 1.1 文件格式

| 项目 | 要求 |
|------|------|
| 模板语言 | HCL (`.tf`) 或 JSON (`.tf.json`) |
| 编码 | UTF-8（.tf.json 不允许含 BOM 头） |
| 主文件 | `main.tf`（约定俗成，RFS 自动识别 .tf 文件） |

### 1.2 压缩包约束

| 项目 | 限制 |
|------|------|
| 格式 | zip / tar.gz / tgz |
| 最大大小 | 1MB（压缩前后均需满足） |
| 最大文件数 | 100 |
| 文件夹名长度 | ≤ 255 字节 |
| 最长相对路径 | ≤ 2048 字节 |
| 排除文件 | 禁止包含 `.tfvars` 文件 |

## 2. 标准文件清单

一个完整的 RFS 部署模板应包含以下文件：

```
solution-name/
├── .extension                # [必选] RFS 扩展配置（分组 + 多语言）
├── versions.tf               # [必选] Provider 版本约束
├── providers.tf              # [必选] Provider 配置
├── variables.tf              # [必选] 输入参数定义
├── main.tf                   # [必选] 资源编排逻辑（核心）
├── outputs.tf                # [推荐] 输出定义
├── userdata/                 # [可选] 应用部署脚本
│   └── install.sh
├── README.md                 # [推荐] 方案文档
└── document/                 # [可选] 图片等静态资源
    └── architecture.png
```

## 3. 文件规范详细说明

### 3.1 versions.tf

```hcl
terraform {
  required_version = ">= 1.2.0"
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.56.0"
    }
  }
}
```

**规则**：
- `source` 必须为 `"huawei.com/provider/huaweicloud"`（RFS 平台专用）
- `version` 用 `>=` 简化号，推荐 `>= 1.56.0`
- 兼容 Terraform 1.5.2

### 3.2 providers.tf

```hcl
provider "huaweicloud" {
  region = var.region
}
```

**规则**：
- 禁止在文件中硬编码 AK/SK
- 通过环境变量传递凭证：`HW_ACCESS_KEY` / `HW_SECRET_KEY` / `HW_REGION_NAME`
- 多 region 场景用 `alias`

### 3.3 variables.tf

```hcl
variable "resource_prefix" {
  description = "资源名称前缀"
  type        = string
  default     = "demo"
}

variable "ecs_password" {
  description = "ECS 管理员密码"
  type        = string
  sensitive   = true
  metadata {
    group = "ecs_config"
  }
}
```

**规则**：
- 每个 variable **必须**提供 `description` 和 `type`
- 敏感信息（密码/Token）**必须**设置 `sensitive = true`
- 非必填参数提供 `default` 值
- 通过 `metadata.group` 关联 .extension 分组

### 3.4 main.tf

**组织顺序**（按依赖关系）：
1. 数据源 (data)
2. 网络资源 (VPC → 子网 → 安全组 → EIP)
3. 存储资源 (EVS / OBS)
4. 计算资源 (ECS / CCE)
5. 数据库 / 中间件 (RDS / DCS)
6. 负载均衡 (ELB)
7. 其他资源

**引用规则**：
- 隐式依赖优先：`huaweicloud_vpc.main.id`
- 避免显式 `depends_on`
- 多实例用 `count` / `for_each`

### 3.5 outputs.tf

```hcl
output "web_url" {
  description = "应用访问地址"
  value       = "http://${huaweicloud_vpc_eip.main.address}:8080"
}
```

包含访问地址、资源 ID 等用户需要的信息。

### 3.6 .extension

```json
{
  "variables": {
    "grouping": {
      "group_name": {
        "label": "分组标签",
        "description": "分组描述"
      }
    }
  },
  "i18n": {
    "zh-cn": {},
    "en-us": {}
  }
}
```

详见 [extension-format.md](extension-format.md)

## 4. 模板上传方式

| 方式 | 说明 |
|------|------|
| **RFS 控制台** | 进入资源编排 → 创建资源栈 → 上传模板文件 |
| **OBS 链接** | 模板文件上传 OBS，使用 `template_uri` 引用 |
| **API** | `POST /v2/templates` multipart/form-data 上传 |

## 5. 常用检查清单

- [ ] all files UTF-8 encoded
- [ ] .tf.json no BOM
- [ ] no .tfvars files in package
- [ ] all variables have `description` and `type`
- [ ] sensitive variables marked `sensitive = true`
- [ ] no hardcoded AK/SK in providers.tf
- [ ] .extension grouping keys match metadata.group values
- [ ] zip size <= 1MB
- [ ] file count <= 100

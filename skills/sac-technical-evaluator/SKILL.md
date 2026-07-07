---
name: sac-technical-evaluator
description: |
  SAC 技术评估子 Agent。负责分析应用架构、设计部署方案、规划云资源、评估安全风险。
  由 sac-architect Agent 在方案设计阶段加载，也可独立使用。
  触发关键词：技术评估、架构设计、资源规划、安全评估、technical evaluation。
  当用户提到"分析一下架构"、"规划资源"、"技术可行性"时触发。
---

# SAC 技术评估子 Agent

本 Agent 负责解决方案的技术评估工作，输出技术评估报告供后续 Agent 使用。

---

## 一、输入参数

| 参数 | 必填 | 说明 | 示例 |
|------|------|------|------|
| solution_name | ✅ | 方案名称 | `headroom-claude-code` |
| region | ✅ | 部署区域（Region ID） | `ap-southeast-1` |
| **deployment_target** | **✅** | **上线站：cn / intl** | **`intl`（编排器传入）** |
| app_type | ✅ | 应用类型 | `Docker` / `Native` / `Hybrid` |
| app_description | ✅ | 应用描述 | `上下文压缩代理` |
| ports | ✅ | 开放端口 | `[8787]` |
| dependencies | ❌ | 外部依赖 | `MaaS API` |
| ecs_recommend | ❌ | ECS 推荐规格 | `x1.2u.4g` |

**⚠️ deployment_target 影响评估：**

| 维度 | cn | intl |
|------|-----|------|
| 镜像源评估 | 需评估华为云镜像可用性 | 直接使用官方源 |
| 网络评估 | 需考虑国内网络限制 | 无特殊限制 |
| 合规评估 | 等保要求、数据主权 | GDPR 等海外合规 |

---

## 二、评估维度

### 2.1 应用架构分析

分析内容：
- 应用技术栈（Python/Node.js/Go/Java 等）
- 运行时依赖（Docker/系统包/运行时环境）
- 数据存储需求（数据库/文件存储/缓存）
- 网络需求（端口/协议/外部访问）

输出格式：
```yaml
architecture:
  stack: "Python 3.10 + Node.js 18"
  runtime: "Docker"
  storage: "PostgreSQL 16 + Redis"
  network:
    - port: 8787
      protocol: HTTP
      description: "Headroom 代理 API"
    - port: 443
      protocol: HTTPS
      description: "MaaS API 出站"
```

### 2.2 部署架构设计

设计内容：
- 部署模式：单机 / 主从 / 集群
- 高可用方案：单可用区 / 多可用区
- 扩展策略：垂直扩展 / 水平扩展

输出格式：
```yaml
deployment:
  mode: "standalone"  # standalone / master-slave / cluster
  ha: "single-az"     # single-az / multi-az
  scaling: "vertical" # vertical / horizontal
  components:
    - name: "application"
      count: 1
      flavor: "x1.2u.4g"
    - name: "database"
      count: 1
      flavor: "x1.2u.4g"
```

### 2.3 云资源规划

规划内容：
- VPC / 子网规划
- 安全组规则
- ECS 规格和磁盘
- EIP 带宽
- 费用估算

输出格式：
```yaml
resources:
  vpc:
    cidr: "172.16.0.0/16"
  subnet:
    cidr: "172.16.1.0/24"
  security_group:
    rules:
      - port: 22
        protocol: TCP
        source: "0.0.0.0/0"
        description: "SSH"
      - port: 8787
        protocol: TCP
        source: "0.0.0.0/0"
        description: "应用端口"
  ecs:
    flavor: "x1.2u.4g"
    os: "Ubuntu 24.04"
    disk:
      type: "SSD"
      size: 40
  eip:
    bandwidth: 300
    charge_mode: "traffic"
  cost:
    monthly: 277.60
    currency: "CNY"
```

### 2.4 安全风险评估

评估内容：
- 网络安全：端口暴露、访问控制
- 数据安全：数据加密、备份策略
- 合规性：数据主权、等保要求

输出格式：
```yaml
security:
  network:
    - risk: "SSH 端口暴露"
      level: "medium"
      mitigation: "限制来源 IP"
    - risk: "应用端口暴露"
      level: "low"
      mitigation: "仅本地访问"
  data:
    - risk: "数据未加密"
      level: "medium"
      mitigation: "启用 TLS"
  compliance:
    - requirement: "数据主权"
      status: "met"
      description: "数据在 ECS 本地处理"
```

---

## 三、输出文件

### 3.1 技术评估报告

文件名：`technical-evaluation.md`
位置：内存传递给后续 Agent

内容结构：
```markdown
# {方案名称} 技术评估报告

## 1. 应用架构分析
## 2. 部署架构设计
## 3. 云资源规划
## 4. 安全风险评估
## 5. 推荐配置
## 6. 风险和缓解措施
```

### 3.2 资源清单

文件名：`resource-plan.yaml`
位置：内存传递给 Script Builder Agent

内容：YAML 格式的资源规划，供 Terraform 脚本生成使用。

---

## 四、评估流程

```
输入参数
    │
    ▼
┌─────────────────┐
│ 应用架构分析    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 部署架构设计    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 云资源规划      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 安全风险评估    │
└────────┬────────┘
         │
         ▼
技术评估报告 + 资源清单
```

---

## 五、评估规范

### 5.1 ECS 规格选择

| 应用类型 | 推荐规格 | 说明 |
|---------|---------|------|
| 轻量应用 | x1.2u.4g | 2vCPU 4GB，适合个人使用 |
| 中等应用 | x1.4u.8g | 4vCPU 8GB，适合小团队 |
| 重型应用 | x1.8u.16g | 8vCPU 16GB，适合企业级 |
| 数据库 | x1.4u.8g | 4vCPU 8GB，需要更多内存 |

### 5.2 磁盘选择

| 应用类型 | 磁盘类型 | 推荐大小 |
|---------|---------|---------|
| 轻量应用 | SAS | 40GB |
| 中等应用 | SSD | 100GB |
| 数据库 | SSD | 200GB |
| 日志密集 | SSD | 500GB |

### 5.3 带宽选择

| 场景 | 带宽 | 说明 |
|------|------|------|
| 个人开发 | 10 Mbit/s | 基本够用 |
| 小团队 | 100 Mbit/s | 日常使用 |
| 企业级 | 300 Mbit/s | 按流量计费 |
| 高并发 | 1000 Mbit/s | 按带宽计费 |

---

## 六、注意事项

1. **区域选择**：由上线站决定 — cn（cn-north-4 北京 / cn-southwest-2 贵阳），intl（ap-southeast-1 香港 / ap-southeast-3 新加坡 / ap-southeast-5 马尼拉 / af-south-1 约翰内斯堡 / la-south-2 圣地亚哥）
2. **镜像选择**：优先 Ubuntu 24.04，其次 Ubuntu 22.04
3. **磁盘类型**：SAS 适合轻量，SSD 适合数据库和 IO 密集
4. **安全组**：默认放行 ICMP 和 SSH(22)，按需开放应用端口
5. **费用估算**：必须包含免责声明

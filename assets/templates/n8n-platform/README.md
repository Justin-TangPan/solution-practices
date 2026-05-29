# 快速部署 n8n 工作流自动化平台

一键将 n8n（GitHub 181k+ Stars，全球最受欢迎的开源工作流自动化平台）部署到华为云 Flexus 云服务器 X 实例。单机部署，零中间件依赖，开箱即用。

## 方案架构

```
                    互联网 / 用户
                         │
                         ▼
               ┌─────────────────┐
               │   EIP (弹性公网IP) │
               └────────┬────────┘
                        │
          ┌─────────────┴──────────────┐
          │ :5678 (Web)   :443 (HTTPS) │
          └─────────────┬──────────────┘
                        │
                        ▼
     ┌──────────────────────────────────────┐
     │       Flexus X 云服务器 (单节点)        │
     │                                      │
     │  ┌────────────────────────────────┐  │
     │  │     n8n (Docker 容器)           │  │
     │  │  ┌──────────────────────────┐  │  │
     │  │  │ Web UI          :5678    │  │  │
     │  │  │ REST API        :5678    │  │  │
     │  │  │ Workflow Engine          │  │  │
     │  │  │ 400+ 集成节点             │  │  │
     │  │  │ AI Agent (LangChain)     │  │  │
     │  │  │ SQLite (本地数据库)       │  │  │
     │  │  └──────────────────────────┘  │  │
     │  └────────────────────────────────┘  │
     │                                      │
     │  定时备份 (cron) → /opt/n8n/backup    │
     └──────────────────────────────────────┘
```

**架构说明**：
- n8n 以 Docker 容器运行在单台 Flexus X 实例上，端口 5678
- 工作流数据、凭证、执行记录使用本地 SQLite 存储，无需额外数据库
- 每天凌晨 2 点自动备份到本地目录，保留最近 7 天
- 支持通过环境变量切换为 PostgreSQL 实现高可用部署

**部署资源清单**：

| 资源 | 规格 | 数量 |
|------|------|------|
| Flexus X ECS | x1.4u.8g（4vCPU 8GB） | 1 |
| VPC | 172.16.0.0/16 | 1 |
| 子网 | 172.16.1.0/24 | 1 |
| 安全组 | — | 1 |
| EIP | 5_bgp（10 Mbit/s 按流量） | 1 |

## 部署指南

### 前置条件

- 已有华为云账号，账户余额充足
- 已开通 ECS（Flexus云服务器X实例）、VPC、EIP 服务
- 部署区域已确认可用区资源充足

### 一键部署

1. 登录华为云 RFS 控制台，进入「资源编排 → 模板管理」
2. 上传本模板压缩包（.zip），或通过 OBS 链接引用
3. 进入「创建资源栈」→ 选择模板 → 填写参数
4. 单击「部署」，等待约 **8-10 分钟**
5. 部署完成后，在「输出」页签获取 n8n 访问地址

### 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| n8n_version | n8n 版本号 | latest |
| vpc_name | VPC 名称 | n8n-workflow-automation-platform-demo |
| security_group_name | 安全组名称 | n8n-workflow-automation-platform-demo |
| ecs_name | ECS 实例名称 | n8n-workflow-automation-platform-demo |
| ecs_flavor | Flexus X 规格 | x1.4u.8g |
| ecs_password | ECS 管理员密码 | *** |
| system_disk_size | 系统盘大小（GB） | 60 |
| bandwidth_size | 带宽大小（Mbit/s） | 10 |
| charging_mode | 计费模式 | postPaid |
| charging_unit | 订购周期类型（包年包月时必填） | month |
| charging_period | 订购周期数 | 1 |

## 开始使用

1. 浏览器访问 `http://<EIP地址>:5678`
2. 首次访问时注册管理员账户（邮箱 + 密码）
3. 进入工作流编辑器，从 400+ 集成节点中选择并拖拽编排
4. 配置 AI 节点（OpenAI / Claude / 华为盘古等）构建 Agent 工作流

**典型场景示例**：

| 场景 | 涉及节点 |
|------|---------|
| AI 邮件自动分类与回复 | Gmail/Exchange + OpenAI + Slack 通知 |
| 客服工单智能分派 | Webhook + LLM 分析 + 飞书/钉钉/企微 |
| 定时数据报表推送 | Cron + MySQL/PostgreSQL + 邮件/企业微信 |
| 社交媒体舆情监控 | RSS/API 轮询 + NLP 情感分析 + 告警 |

## 预估费用

| 资源 | 规格 | 预估月费（元） |
|------|------|--------------|
| Flexus X ECS | x1.4u.8g（4vCPU 8GB，按需） | ~220 |
| 系统盘 | SAS 高IO 60GB | ~20 |
| EIP | 10 Mbit/s 按流量计费 | ~100 |
| **合计** | | **~340/月** |

> 以上为北京四区域（cn-north-4）参考价格，实际以华为云官网为准。包年包月价格更低。

## 故障排查

所有安装日志汇聚到单一文件，出问题时只需查看一个文件：

```bash
ssh root@<EIP>

# 查看全部安装日志
cat /var/log/n8n.log

# 按阶段筛选关键信息
grep "Stage" /var/log/n8n.log          # 各阶段 PASS/FAIL
grep "FAIL\|ERROR\|WARN" /var/log/n8n.log  # 只看异常
grep "healthz" /var/log/n8n.log        # 健康检查详情
```

**单独重试某个阶段**（修复问题后不必从头跑）：
```bash
bash /opt/n8n/scripts/04-start-n8n.sh   # 重试启动阶段
```

**常见问题快速检查**：
```bash
docker ps -a                   # 容器是否在运行
docker logs n8n --tail 50     # n8n 容器日志
systemctl status docker        # Docker 是否运行
df -h /                        # 磁盘是否满了
```

## 快速卸载

1. 登录华为云 RFS 控制台 → 资源栈
2. 找到本方案对应的资源栈
3. 单击「删除」→ 输入 `Delete` → 确认
4. 所有资源（VPC、ECS、EIP、安全组）将自动释放

---

## 关于 n8n

[n8n](https://github.com/n8n-io/n8n) 是全球最受欢迎的开源工作流自动化平台（GitHub 181k+ Stars），被称为"开发者版的 Zapier"：

- **400+ 集成**：数据库、SaaS、API、文件系统、AI 模型开箱即用
- **可视化编排**：拖拽式工作流编辑器，支持条件分支、循环、错误处理、子流程
- **AI Native**：原生集成 LangChain，支持 LLM Agent、RAG 管道、工具调用等 AI 工作流
- **代码灵活**：支持 JavaScript/Python 自定义代码节点，兼顾低代码与专业开发
- **自托管可控**：数据不出企业，完全掌控隐私、合规与成本

# JiuwenSwarm 华为云解决方案实践 — 方案详情

> **方案状态：** 中国站正式入口，`v4` 云测通过；未生产发布
> **部署区域：** 华北-北京四（`cn-north-4`）
> **部署形态：** RFS 标准单机版
> **应用版本：** JiuwenSwarm `0.2.2`

## 1. 解决方案概述

JiuwenSwarm 是面向开发者和团队的 Agent 系统，支持通过自然语言组织多 Agent 协作、Skill 和工具调用。本实践使用华为云资源编排服务 RFS，把网络、计算、公网入口与应用初始化组合为一个标准单机资源栈。

正式模板一次创建 VPC、子网、安全组、安全组规则、EIP 和 ECS 6 类资源，并在 Ubuntu 24.04 ECS 中通过 Python 虚拟环境安装固定版本 `jiuwenswarm==0.2.2`。初始化数据存放在 `/var/lib/jiuwenswarm`，应用以非登录系统用户运行并由 systemd 托管。

本实践不在模板中接收或保存模型 API Key。用户在部署完成后自行配置模型服务，因此基础设施部署与模型凭证管理相互分离。

## 2. 客户价值

- **手工步骤压缩为一次堆栈部署**：由 RFS 统一创建 6 类云资源并执行应用初始化，减少逐项创建网络、主机和安装环境的操作。
- **固定应用版本**：明确安装 JiuwenSwarm `0.2.2`，便于复核代码、依赖和测试结果。
- **可重复清理**：资源归属于同一 RFS 栈，可通过删除资源栈集中卸载；删除前仍需按需备份应用数据。
- **凭证后配置**：模型 API Key 不属于 RFS 参数，避免敏感凭证进入模板源码。

以上价值来自模板可验证行为，不代表节省比例、性能提升或业务收益承诺。

## 3. 架构与部署方式

### 3.1 资源架构

| 层次 | 组件 | 配置与职责 |
|---|---|---|
| 编排 | RFS 资源栈 | 创建、更新和删除方案资源 |
| 网络 | VPC、子网 | `172.16.0.0/16` VPC 和 `172.16.1.0/24` 子网 |
| 边界 | 安全组、2 条规则 | 官方默认 Web 端口 TCP 5173 对公网开放；TCP 22 仅允许 Cloud Shell 固定出口 `/32` |
| 公网 | EIP | 全动态 BGP，默认 300 Mbit/s，按流量、按需计费 |
| 计算 | ECS | 默认 `x1.4u.8g`、Ubuntu 24.04、80 GiB 高 IO 系统盘 |
| 应用 | JiuwenSwarm | 官方默认 5173 Web 服务、Python venv、固定应用版本、systemd、数据目录 `/var/lib/jiuwenswarm` |

客户端通过 `http://<EIP>:5173` 访问应用。模板不提供端口变量，也不设置 `FRONTEND_PORT` 改写上游官方默认值，避免误改到后端或其他服务接口。ECS 直接安装指定版本 `jiuwenswarm==0.2.2`，并执行最多约 120 秒的启动探测。

### 3.2 参数面

正式模板公开以下全部 8 个标准变量：

| 变量 | 默认值 | 作用 |
|---|---|---|
| `solution_name` | `jiuwenswarm` | 资源名称前缀 |
| `ecs_flavor` | `x1.4u.8g` | ECS 规格 |
| `ecs_password` | 无 | ECS root 密码，敏感输入 |
| `system_disk_size` | `80` | 系统盘大小，40—1024 GiB |
| `bandwidth_size` | `300` | EIP 带宽，1—300 Mbit/s；按流量、按需计费 |
| `charging_mode` | `postPaid` | ECS 按需或包年包月 |
| `charging_unit` | `month` | ECS 订购周期单位 |
| `charging_period` | `1` | ECS 订购周期；月 1—9，年应为 1—3 |

输出为 `jiuwenswarm_url` 和 `ecs_public_ip`。Web 沿用上游官方默认 TCP 5173，应用不提供独立入口认证。

### 3.3 当前部署边界

本实践只有单 ECS 标准版，不包括高可用集群、ELB、域名、受信任 CA 证书、WAF、集中日志、自动备份、跨可用区容灾或自动扩缩容，不能把当前模板描述为生产高可用架构。

## 4. 应用场景

- **产品与功能验证**：快速建立独立 JiuwenSwarm 环境，验证规划、性能和集群模式及模型配置流程。
- **团队内部试用**：为少量授权成员提供短期验证环境。
- **Agent 与 Skill 开发实验**：在隔离的测试 ECS 中验证工具、Skill 和多 Agent 工作流。

不适用场景包括面向互联网公开服务、生产敏感数据处理、需要合规认证入口的系统，以及对高可用和恢复时间有明确承诺的业务。

## 5. 安全设计与已知风险

### 5.1 已实现措施

- Web 沿用上游官方默认 TCP 5173；模板不提供修改该默认值的客户参数。
- SSH 仅允许固定 Cloud Shell 出口访问 TCP 22。
- ECS 密码参数标记为敏感值，模型 API Key 不进入 Terraform 参数。
- JiuwenSwarm 使用独立的 `jiuwenswarm` 用户运行，systemd 启用 `NoNewPrivileges`、`PrivateTmp`、`ProtectSystem=strict`、`ProtectHome=true` 和 `UMask=0077`。
- 应用数据目录权限受限。

### 5.2 必须接受或修复的风险

- **公网入口无 TLS 和应用认证**：官方默认 5173 接口对公网开放，只适合云测和非敏感验证；正式公网生产使用前必须增加可信 TLS、认证和访问控制。
- **单机故障域**：ECS 或系统盘故障会中断服务，模板没有自动恢复或备份机制。
- **Agent 工具风险**：Agent 可能读取、修改文件或执行工具；必须限制数据、Skill、MCP 和工具权限。

因此当前实践严禁输入生产敏感凭证或业务数据。若面向正式公网用户，应增加受信任证书、强认证、访问控制、审计、备份和高可用能力。

## 6. 支持区域与版本

| 项目 | 范围 |
|---|---|
| 站点 | 华为云中国站 |
| 区域 | 华北-北京四（`cn-north-4`） |
| 变体 | `jiuwenswarm` 标准单机版 |
| 候选文件 | `deploying-jiuwenswarm_v4.tf` |
| 正式文件 | `deploying-jiuwenswarm.tf` |
| JiuwenSwarm | `0.2.2` |
| 操作系统 | Ubuntu 24.04 server 64bit 公共镜像，取区域最新匹配镜像 |

用户已确认候选 `v4` 在真实华为云 RFS 环境云测通过。区域规格库存、镜像和软件源可用性仍可随时间变化，后续发布需重新回归。

## 7. 成本说明

方案支持 ECS 按需和包年包月两种选择；EIP 在两种情况下均固定为按需、按流量计费。费用主要由 ECS 规格及使用时长、系统盘、EIP 带宽和公网流量构成。

本文档不臆造金额。请使用 [华为云价格计算器](https://www.huaweicloud.com/pricing/) 按 `cn-north-4` 的实时价格分别估算按需和包年包月场景。最终费用以订单和账单为准。

## 8. 验证、运维与卸载摘要

云测至少应验证：RFS 栈成功、`jiuwenswarm.service` 为 `active`、公网和本机 5173 健康检查成功、安装版本为 `0.2.2`、模型测试调用成功，以及 ECS 重启后服务自动恢复。

运维排障入口：

```bash
sudo systemctl status jiuwenswarm.service --no-pager
sudo journalctl -u jiuwenswarm.service -n 200 --no-pager
sudo tail -n 200 /var/log/jiuwenswarm-bootstrap.log
```

删除资源栈前，应按需备份 `/var/lib/jiuwenswarm`。随后在 RFS 删除栈并选择删除资源，确认 ECS、EIP 和网络资源均释放。详细步骤、变量校验和故障处理见《JiuwenSwarm 部署指南》。

## 9. 上线信息

已生成与云测通过候选 `v4` 字节一致的无版本正式模板。尚未生成生产 OBS 对象或正式 RFS 部署 URL；公网入口无 TLS 和应用认证，不得将当前形态宣称为生产安全方案。

## 10. 参考资料

- [JiuwenSwarm 上游仓库](https://gitcode.com/openJiuwen/jiuwenswarm)
- [华为云价格计算器](https://www.huaweicloud.com/pricing/)
- [华为云资源编排服务 RFS 文档](https://support.huaweicloud.com/aos/)

## 11. 修订记录

| 日期 | 版本 | 修订说明 |
|---|---|---|
| 2026-07-14 | 候选 0.1 | 基于 JiuwenSwarm `0.2.2` 与 RFS 候选 `v1` 形成中国站方案详情；状态为未云测、不可上架。 |
| 2026-07-15 | 候选 0.2 | 同步 `v2` HTTPS、回环绑定、自签证书核验和完整哈希依赖锁；状态仍为未云测、不可上架。 |
| 2026-07-15 | 候选 0.3 | 按 SAC/Hermes 约定收敛 `v3`：300M 按需 EIP、沿用上游官方默认 5173、全内联安装，不向客户开放端口、CIDR或依赖 URL。 |
| 2026-07-16 | 正式 0.4 | 用户确认 `v4` 云测通过，字节级晋升为 `deploying-jiuwenswarm.tf`；保留候选用于审计。 |

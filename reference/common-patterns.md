---
name: common-patterns
description: 华为云解决方案常见部署模式 — 按业务场景分类的标准资源组合和模板模式
---

# 常见部署模式

## 模式 1: Web 应用单机部署

**适用场景**：中小网站、博客、开发测试环境

```hcl
# 资源组合
huaweicloud_vpc                       # VPC
huaweicloud_vpc_subnet                # 子网
huaweicloud_networking_secgroup       # 安全组（开放 80/443/22）
huaweicloud_vpc_eip                   # 弹性公网 IP
huaweicloud_compute_instance          # ECS（2C4G 起步）
  + userdata: install_web.sh          #  安装 Nginx/Apache + 应用
```

**参考模板**：`assets/templates/web-application/`

## 模式 2: Web 应用高可用集群

**适用场景**：生产环境 Web 服务

```hcl
# 资源组合
huaweicloud_vpc                       # VPC
huaweicloud_vpc_subnet                # 子网（至少2个可用区）
huaweicloud_networking_secgroup       # 安全组
huaweicloud_vpc_eip                   # EIP
huaweicloud_elb_loadbalancer          # ELB（公网类型）
huaweicloud_lb_listener               # HTTP/HTTPS 监听
huaweicloud_lb_pool                   # 后端服务器组
huaweicloud_compute_instance ×2       # ECS 多可用区部署
  + userdata: install_app.sh          #  应用安装脚本
huaweicloud_rds_instance              # RDS 主备
huaweicloud_dcs_instance              # Redis 缓存（可选）
```

## 模式 3: API + 数据库服务

**适用场景**：REST API 后端服务

```hcl
# 资源组合
huaweicloud_vpc
huaweicloud_vpc_subnet
huaweicloud_networking_secgroup       # 仅开放 API 端口
huaweicloud_vpc_eip
huaweicloud_compute_instance          # API Server
  + userdata: install_api.sh          #  安装 API 服务
huaweicloud_rds_instance              # 业务数据库
huaweicloud_dcs_instance              # Redis 缓存
huaweicloud_obs_bucket                # 静态文件/附件存储
```

## 模式 4: 容器化微服务

**适用场景**：微服务架构、云原生应用

```hcl
# 资源组合
huaweicloud_vpc
huaweicloud_vpc_subnet
huaweicloud_networking_secgroup
huaweicloud_vpc_eip
huaweicloud_cce_cluster               # CCE 集群
huaweicloud_cce_node_pool             # 节点池
huaweicloud_swr_organization          # 镜像仓库组织
huaweicloud_swr_repository            # 镜像仓库
huaweicloud_elb_loadbalancer          # 入口负载均衡
huaweicloud_rds_instance              # 数据库
huaweicloud_dcs_instance              # Redis
huaweicloud_obs_bucket                # 对象存储
```

## 模式 5: AI/ML 推理部署

**适用场景**：DeepSeek、Llama 等 LLM 推理

```hcl
# 资源组合
huaweicloud_vpc
huaweicloud_vpc_subnet
huaweicloud_networking_secgroup
huaweicloud_vpc_eip
huaweicloud_compute_instance          # GPU 加速型 ECS
  + userdata: install_inference.sh    #  安装推理引擎
huaweicloud_obs_bucket                # 模型文件存储
huaweicloud_sfs_turbo                 # （可选）共享文件系统
```

## 模式 6: 智能文档处理

**适用场景**：文档解析、OCR、RAG 知识库

```hcl
# 资源组合
huaweicloud_vpc
huaweicloud_vpc_subnet
huaweicloud_networking_secgroup
huaweicloud_vpc_eip
huaweicloud_compute_instance ×N       # 应用 + 处理节点
  + userdata: install_app.sh
huaweicloud_elb_loadbalancer          # 访问入口
huaweicloud_rds_instance              # 元数据存储
huaweicloud_dcs_instance              # Redis 缓存/队列
huaweicloud_obs_bucket                # 文档存储
huaweicloud_fgs_function              # （可选）触发处理
```

## 模式 7: CI/CD 持续集成

**适用场景**：代码仓库 + 自动构建

```hcl
# 资源组合
huaweicloud_vpc
huaweicloud_vpc_subnet
huaweicloud_networking_secgroup
huaweicloud_vpc_eip
huaweicloud_compute_instance          # Jenkins Server
  + userdata: install_jenkins.sh
huaweicloud_compute_instance          # Gerrit/SonarQube
  + userdata: install_gerrit.sh
huaweicloud_obs_bucket                # 构建产物存储
huaweicloud_swr_organization          # 镜像仓库
```

## 模式选择指南

| 用户需求 | 推荐模式 |
|---------|---------|
| "我要部署一个网站" | 模式 1 或 2（看是否需要高可用）|
| "我有一个 Java/Go 后端" | 模式 3 |
| "我的应用是 Docker 化部署" | 模式 4 |
| "我想跑 AI 模型推理" | 模式 5 |
| "我要做文档识别/RAG 系统" | 模式 6 |
| "我要搭建 CI/CD 流水线" | 模式 7 |

## 数据源 (Data Source) 常用场景

```hcl
# 查询可用区
data "huaweicloud_availability_zones" "main" {}

# 查询规格
data "huaweicloud_compute_flavors" "main" {
  availability_zone = data.huaweicloud_availability_zones.main.names[0]
  performance_type  = "normal"
  cpu_core_count    = 4
  memory_size       = 8
}

# 查询镜像
data "huaweicloud_images_image" "main" {
  name        = "Ubuntu 22.04"
  most_recent = true
}

# 查询已有网络
data "huaweicloud_vpc" "existing" {
  name = var.existing_vpc_name
}
```

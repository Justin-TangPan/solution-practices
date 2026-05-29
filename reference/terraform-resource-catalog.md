---
name: terraform-resource-catalog
description: 华为云 Terraform Provider 资源分类速查表 — 按服务分类整理所有常用资源
---

# 华为云 Terraform Provider 资源分类速查

Provider Source: `huawei.com/provider/huaweicloud` (RFS 平台) / `huaweicloud/huaweicloud` (Terraform Registry)
最新 Provider 版本: v1.97+（支持 800+ 资源）
推荐版本约束: `>= 1.56.0`

---

## 网络 (VPC)

| 资源 | 用途 |
|------|------|
| `huaweicloud_vpc` | 创建 VPC |
| `huaweicloud_vpc_subnet` | 创建子网 |
| `huaweicloud_vpc_eip` | 弹性公网 IP |
| `huaweicloud_vpc_eip_associate` | EIP 绑定到实例 |
| `huaweicloud_networking_secgroup` | 安全组 |
| `huaweicloud_networking_secgroup_rule` | 安全组规则 |
| `huaweicloud_vpc_route` | 路由表条目 |
| `huaweicloud_vpc_route_table` | 路由表 |
| `huaweicloud_vpc_network_acl` | 网络 ACL |
| `huaweicloud_nat_gateway` | NAT 网关 |
| `huaweicloud_vpc_peering_connection` | VPC 对等连接 |
| `huaweicloud_vpcep_endpoint` | VPC Endpoint |
| `huaweicloud_vpcep_service` | VPC Endpoint 服务 |
| `huaweicloud_vpn_gateway` | VPN 网关 |
| `huaweicloud_vpn_connection` | VPN 连接 |

## 计算 (ECS)

| 资源 | 用途 |
|------|------|
| `huaweicloud_compute_instance` | ECS 云服务器 |
| `huaweicloud_compute_keypair` | SSH 密钥对 |
| `huaweicloud_compute_servergroup` | 云服务器组（亲和/反亲和） |
| `huaweicloud_compute_volume_attach` | 挂载云硬盘 |
| `huaweicloud_compute_interface_attach` | 挂载网卡 |
| `huaweicloud_compute_eip_associate` | 关联 EIP |
| `huaweicloud_as_group` | 弹性伸缩组 |
| `huaweicloud_as_configuration` | 弹性伸缩配置 |
| `huaweicloud_as_policy` | 弹性伸缩策略 |

## 数据库 (RDS)

| 资源 | 用途 |
|------|------|
| `huaweicloud_rds_instance` | RDS 实例（MySQL / PostgreSQL / SQL Server） |
| `huaweicloud_rds_read_replica_instance` | RDS 只读副本 |
| `huaweicloud_rds_mysql_database` | MySQL 数据库 |
| `huaweicloud_rds_mysql_account` | MySQL 账号 |
| `huaweicloud_rds_parametergroup` | 参数组 |

## 内存数据库 (DCS)

| 资源 | 用途 |
|------|------|
| `huaweicloud_dcs_instance` | Redis / Memcached 实例 |
| `huaweicloud_dcs_backup` | DCS 备份 |

## 分布式数据库 (GaussDB)

| 资源 | 用途 |
|------|------|
| `huaweicloud_gaussdb_mysql_instance` | GaussDB MySQL 实例 |
| `huaweicloud_gaussdb_mysql_database` | GaussDB MySQL 数据库 |
| `huaweicloud_gaussdb_mysql_account` | GaussDB MySQL 账号 |
| `huaweicloud_gaussdb_opengauss_instance` | GaussDB OpenGauss 实例 |

## 负载均衡 (ELB)

| 资源 | 用途 |
|------|------|
| `huaweicloud_elb_loadbalancer` | 弹性负载均衡 |
| `huaweicloud_lb_listener` | 监听器 |
| `huaweicloud_lb_pool` | 后端服务器组 |
| `huaweicloud_lb_member` | 后端服务器 |
| `huaweicloud_lb_monitor` | 健康检查 |
| `huaweicloud_lb_certificate` | SSL 证书 |

## 对象存储 (OBS)

| 资源 | 用途 |
|------|------|
| `huaweicloud_obs_bucket` | OBS 桶 |
| `huaweicloud_obs_bucket_object` | OBS 对象 |
| `huaweicloud_obs_bucket_policy` | OBS 桶策略 |

## 存储 (EVS / SFS)

| 资源 | 用途 |
|------|------|
| `huaweicloud_evs_volume` | 云硬盘 |
| `huaweicloud_sfs_file_system` | SFS 文件系统 |
| `huaweicloud_sfs_turbo` | SFS Turbo |

## 容器 (CCE / SWR)

| 资源 | 用途 |
|------|------|
| `huaweicloud_cce_cluster` | CCE 集群 |
| `huaweicloud_cce_node` | CCE 节点 |
| `huaweicloud_cce_node_pool` | CCE 节点池 |
| `huaweicloud_cce_addon` | CCE 插件 |
| `huaweicloud_swr_organization` | SWR 组织 |
| `huaweicloud_swr_repository` | SWR 镜像仓库 |

## 函数计算 (FunctionGraph)

| 资源 | 用途 |
|------|------|
| `huaweicloud_fgs_function` | 函数 |
| `huaweicloud_fgs_trigger` | 函数触发器 |

## 消息与通知 (DMS / SMN)

| 资源 | 用途 |
|------|------|
| `huaweicloud_dms_kafka_instance` | Kafka 实例 |
| `huaweicloud_dms_rocketmq_instance` | RocketMQ 实例 |
| `huaweicloud_smn_topic` | SMN 主题 |
| `huaweicloud_smn_subscription` | SMN 订阅 |

## 安全 (WAF / Anti-DDoS)

| 资源 | 用途 |
|------|------|
| `huaweicloud_waf_dedicated_instance` | WAF 独享实例 |
| `huaweicloud_waf_policy` | WAF 策略 |
| `huaweicloud_waf_rule_blacklist` | WAF 黑名单规则 |
| `huaweicloud_antiddos_basic` | Anti-DDoS 基础防护 |

## DNS

| 资源 | 用途 |
|------|------|
| `huaweicloud_dns_zone` | DNS 域名 |
| `huaweicloud_dns_recordset` | DNS 记录集 |

## 日志 (LTS)

| 资源 | 用途 |
|------|------|
| `huaweicloud_lts_group` | LTS 日志组 |
| `huaweicloud_lts_stream` | LTS 日志流 |

## IAM

| 资源 | 用途 |
|------|------|
| `huaweicloud_identity_user` | IAM 用户 |
| `huaweicloud_identity_group` | IAM 用户组 |
| `huaweicloud_identity_role` | IAM 角色 |
| `huaweicloud_identity_agency` | IAM 委托 |

## 备份 (CBR)

| 资源 | 用途 |
|------|------|
| `huaweicloud_cbr_vault` | CBR 存储库 |
| `huaweicloud_cbr_policy` | CBR 备份策略 |

## 标签 (TMS)

| 资源 | 用途 |
|------|------|
| `huaweicloud_tms_tags` | 资源标签 |

#======================================
# 基础配置
#======================================
variable "region" {
  description = "部署区域"
  type        = string
  default     = "cn-north-4"
}

variable "cluster_name" {
  description = "集群名称，用作资源名前缀"
  type        = string
  default     = "webcluster"
  metadata {
    group = "ecs_config"
  }
}

variable "availability_zone_1" {
  description = "第一个可用区"
  type        = string
  metadata {
    group = "network_config"
  }
}

variable "availability_zone_2" {
  description = "第二个可用区"
  type        = string
  metadata {
    group = "network_config"
  }
}

#======================================
# VPC 配置
#======================================
variable "vpc_cidr" {
  description = "VPC 地址段"
  type        = string
  default     = "10.0.0.0/16"
  metadata {
    group = "network_config"
  }
}

variable "subnet_cidr_1" {
  description = "子网1 地址段"
  type        = string
  default     = "10.0.1.0/24"
  metadata {
    group = "network_config"
  }
}

variable "subnet_cidr_2" {
  description = "子网2 地址段"
  type        = string
  default     = "10.0.2.0/24"
  metadata {
    group = "network_config"
  }
}

#======================================
# ECS 配置
#======================================
variable "ecs_flavor" {
  description = "ECS 规格"
  type        = string
  default     = "s6.large.2"
  metadata {
    group = "ecs_config"
  }
}

variable "image_id" {
  description = "镜像 ID（推荐 Ubuntu 22.04）"
  type        = string
  metadata {
    group = "ecs_config"
  }
}

variable "ecs_password" {
  description = "ECS 管理员密码（所有节点一致）"
  type        = string
  sensitive   = true
  metadata {
    group = "ecs_config"
  }
}

variable "ecs_count" {
  description = "ECS 节点数量"
  type        = number
  default     = 2
  metadata {
    group = "ecs_config"
  }
}

#======================================
# ELB 配置
#======================================
variable "elb_bandwidth" {
  description = "ELB 带宽 (Mbit/s)"
  type        = number
  default     = 10
  metadata {
    group = "elb_config"
  }
}

#======================================
# RDS 配置
#======================================
variable "rds_flavor" {
  description = "RDS 规格"
  type        = string
  default     = "rds.mysql.n1.large.2"
  metadata {
    group = "rds_config"
  }
}

variable "db_password" {
  description = "数据库管理员密码"
  type        = string
  sensitive   = true
  metadata {
    group = "rds_config"
  }
}

variable "db_name" {
  description = "初始数据库名称"
  type        = string
  default     = "webapp"
  metadata {
    group = "rds_config"
  }
}

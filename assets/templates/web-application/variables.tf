#======================================
# 基础配置
#======================================
variable "region" {
  description = "部署区域"
  type        = string
  default     = "cn-north-4"
}

variable "web_name" {
  description = "Web 应用名称，用作资源名前缀"
  type        = string
  default     = "myweb"
  metadata {
    group = "app_config"
  }
}

#======================================
# 网络配置
#======================================
variable "vpc_cidr" {
  description = "VPC 地址段"
  type        = string
  default     = "10.0.0.0/16"
  metadata {
    group = "network_config"
  }
}

variable "subnet_cidr" {
  description = "子网地址段"
  type        = string
  default     = "10.0.1.0/24"
  metadata {
    group = "network_config"
  }
}

variable "availability_zone" {
  description = "ECS 可用区"
  type        = string
  metadata {
    group = "network_config"
  }
}

variable "availability_zone_rds" {
  description = "RDS 可用区（通常与 ECS 一致）"
  type        = string
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
  description = "ECS 管理员密码"
  type        = string
  sensitive   = true
  metadata {
    group = "ecs_config"
  }
}

variable "bandwidth_size" {
  description = "带宽大小 (Mbit/s)"
  type        = number
  default     = 5
  metadata {
    group = "network_config"
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

#======================================
# 应用配置
#======================================
variable "domain_name" {
  description = "应用访问域名（可选）"
  type        = string
  default     = ""
  metadata {
    group = "app_config"
  }
}

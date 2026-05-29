# ============================================================
# OpenHuman 云端开发环境 — 输入变量定义
# ============================================================

# ---------- 基础配置 ----------
variable "region" {
  description = "部署区域"
  type        = string
  default     = "cn-north-4"
  metadata {
    group = "basic_config"
  }
}

variable "resource_prefix" {
  description = "资源名称前缀"
  type        = string
  default     = "openhuman-dev"
  metadata {
    group = "basic_config"
  }
}

# ---------- 网络配置 ----------
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
  description = "可用区（如 cn-north-4a）"
  type        = string
  default     = "cn-north-4a"
  metadata {
    group = "network_config"
  }
}

# ---------- ECS 配置 ----------
variable "ecs_flavor" {
  description = "Flexus X 实例规格"
  type        = string
  default     = "x1.2u.4g"
  metadata {
    group = "ecs_config"
  }
}

variable "image_id" {
  description = "镜像 ID（推荐 Ubuntu 22.04）"
  type        = string
  default     = "Ubuntu 22.04"
  metadata {
    group = "ecs_config"
  }
}

variable "ecs_password" {
  description = "ECS root 密码（8-26位，含大写+小写+数字+特殊字符中三种）"
  type        = string
  sensitive   = true
  metadata {
    group = "ecs_config"
  }
}

variable "system_disk_size" {
  description = "系统盘大小 (GB)"
  type        = number
  default     = 40
  metadata {
    group = "ecs_config"
  }
}

variable "bandwidth_size" {
  description = "弹性公网带宽 (Mbit/s)"
  type        = number
  default     = 5
  metadata {
    group = "network_config"
  }
}

variable "charging_mode" {
  description = "计费模式：postPaid（按需）或 prePaid（包年包月）"
  type        = string
  default     = "postPaid"
  metadata {
    group = "basic_config"
  }
}

# ---------- OpenHuman 配置 ----------
variable "openhuman_repo" {
  description = "OpenHuman 仓库地址"
  type        = string
  default     = "https://github.com/tinyhumansai/openhuman.git"
  metadata {
    group = "ecs_config"
  }
}

variable "ollama_model" {
  description = "Ollama 模型（2u4g 推荐小模型: qwen2.5:0.5b）"
  type        = string
  default     = "qwen2.5:0.5b"
  metadata {
    group = "ecs_config"
  }
}

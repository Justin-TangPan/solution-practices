variable "region" {
  description = "部署区域"
  type        = string
  default     = "cn-north-4"
}

variable "vpc_name" {
  description = "VPC 名称"
  type        = string
  default     = "solution-vpc"
  metadata {
    group = "network_config"
  }
}

variable "vpc_cidr" {
  description = "VPC 地址段"
  type        = string
  default     = "10.0.0.0/16"
  metadata {
    group = "network_config"
  }
}

variable "subnet_name" {
  description = "子网名称"
  type        = string
  default     = "solution-subnet"
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
  description = "可用区"
  type        = string
  metadata {
    group = "ecs_config"
  }
}

variable "ecs_name" {
  description = "ECS 实例名称"
  type        = string
  default     = "solution-ecs"
  metadata {
    group = "ecs_config"
  }
}

variable "ecs_flavor" {
  description = "ECS 规格"
  type        = string
  metadata {
    group = "ecs_config"
  }
}

variable "image_id" {
  description = "镜像 ID"
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

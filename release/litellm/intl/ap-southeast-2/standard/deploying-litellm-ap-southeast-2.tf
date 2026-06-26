terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.20.0"
    }
  }
}

provider "huaweicloud" {
  region = "ap-southeast-2"
}

variable "solution_name" {
  default     = "litellm-llm-gateway"
  description = "Solution name, 4-24 chars, lowercase letters/digits/hyphens, must start with a lowercase letter."
  type        = string
  nullable    = false
}

variable "ecs_flavor" {
  default     = "x1.8u.16g"
  description = "ECS flavor. Recommended x1.8u.16g (8vCPUs 16GiB) for production workloads. Enable performance mode in console for best results."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^x1\\.([1-9]|1[0-6])u\\.([1-9][0-9]{0,1}|1[0-2][0-8])g$", var.ecs_flavor))
    error_message = "Invalid ECS flavor format. Example: x1.4u.8g"
  }
}

variable "ecs_password" {
  default     = ""
  description = "ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special characters."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "db_password" {
  default     = ""
  description = "PostgreSQL password, 8-26 chars. Used by LiteLLM for internal database (virtual keys, spend tracking)."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "master_key" {
  default     = ""
  description = "LiteLLM master key, must start with 'sk-'. Used for Admin UI login and API authentication."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "salt_key" {
  default     = ""
  description = "LiteLLM salt key for encrypting stored API keys. CANNOT be changed once used. Leave empty to auto-generate."
  type        = string
  sensitive   = true
  nullable    = true
}

variable "system_disk_size" {
  default     = 200
  description = "System disk size in GB (high-IO SSD). Docker images + PG data + logs. 200GB recommended for production. Range: 40-1024."
  type        = number
  nullable    = false
  validation {
    condition     = var.system_disk_size >= 40 && var.system_disk_size <= 1024
    error_message = "System disk size must be between 40 and 1024 GB."
  }
}

variable "bandwidth_size" {
  default     = 200
  description = "EIP bandwidth in Mbit/s, traffic billing. Range: 1-300. Default: 200."
  type        = number
  nullable    = false
  validation {
    condition     = var.bandwidth_size >= 1 && var.bandwidth_size <= 300
    error_message = "Bandwidth must be between 1 and 300 Mbit/s."
  }
}

variable "charging_mode" {
  default     = "postPaid"
  description = "Billing mode: postPaid (pay-per-use) or prePaid (subscription). Default: postPaid."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "Must be postPaid or prePaid."
  }
}

variable "charging_unit" {
  default     = "month"
  description = "Subscription unit: month or year. Required when charging_mode is prePaid."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "Must be month or year."
  }
}

variable "charging_period" {
  default     = 1
  description = "Subscription period: 1-9 (month) or 1-3 (year). Required when charging_mode is prePaid."
  type        = number
  nullable    = false
  validation {
    condition     = var.charging_period >= 1 && var.charging_period <= 9
    error_message = "Period must be 1-9."
  }
}

variable "obs_base_url" {
  default     = "https://tp-00940108.obs.cn-south-1.myhuaweicloud.com"
  description = "OBS bucket URL for downloading deployment scripts."
  type        = string
  nullable    = false
}

data "huaweicloud_images_image" "Ubuntu" {
  most_recent = true
  name        = "Ubuntu 24.04 server 64bit"
  visibility  = "public"
}

resource "huaweicloud_vpc" "vpc" {
  name = "${var.solution_name}-vpc"
  cidr = "172.16.0.0/16"
}

resource "huaweicloud_vpc_subnet" "subnet" {
  name       = "${var.solution_name}-subnet"
  cidr       = "172.16.1.0/24"
  gateway_ip = "172.16.1.1"
  vpc_id     = huaweicloud_vpc.vpc.id
}

resource "huaweicloud_networking_secgroup" "secgroup" {
  name = "${var.solution_name}-sg"
}

resource "huaweicloud_networking_secgroup_rule" "allow_ping" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Allow ping for connectivity test"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "litellm_api" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "LiteLLM Proxy API and Admin UI"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 4000
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "prometheus_ui" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Prometheus monitoring dashboard"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 9090
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "SSH access via Cloud Shell"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 22
  remote_ip_prefix  = "121.36.59.153/32"
}

resource "huaweicloud_vpc_eip" "vpc_eip" {
  name = "${var.solution_name}-eip"
  bandwidth {
    name        = "${var.solution_name}-bw"
    share_type  = "PER"
    size        = var.bandwidth_size
    charge_mode = "traffic"
  }
  publicip {
    type = "5_bgp"
  }
  charging_mode = "postPaid"
}

resource "huaweicloud_compute_instance" "compute_instance" {
  name                        = "${var.solution_name}-ecs"
  image_id                    = data.huaweicloud_images_image.Ubuntu.id
  flavor_id                   = var.ecs_flavor
  security_group_ids          = [huaweicloud_networking_secgroup.secgroup.id]
  system_disk_type            = "SSD"
  system_disk_size            = var.system_disk_size
  admin_pass                  = var.ecs_password
  delete_disks_on_termination = true
  network {
    uuid = huaweicloud_vpc_subnet.subnet.id
  }
  agent_list    = "hss,ces"
  eip_id        = huaweicloud_vpc_eip.vpc_eip.id
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
  tags = {
    app = "LiteLLM"
  }
  user_data = "#!/bin/bash\necho 'root:${var.ecs_password}' | chpasswd\nwget -P /home/ ${var.obs_base_url}/litellm-hk/install_litellm.sh\nbash /home/install_litellm.sh \"${var.db_password}\" \"${var.master_key}\" \"${var.salt_key}\"\nrm -rf /home/install_litellm.sh"
}

output "access_info" {
  description = "Deployment access information"
  value       = <<-EOT
Wait ~10 minutes for deployment to complete, then access:

Admin UI:   http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/ui
API:        http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/v1/chat/completions
Health:     http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/health/liveliness
Prometheus: http://${huaweicloud_vpc_eip.vpc_eip.address}:9090

SSH: ssh root@${huaweicloud_vpc_eip.vpc_eip.address}

Add provider API keys:
  vi /opt/litellm/.env
  cd /opt/litellm && docker compose restart

Logs: /var/log/litellm-bootstrap.log
EOT
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}

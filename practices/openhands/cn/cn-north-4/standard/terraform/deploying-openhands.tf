terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.20.0"
    }
  }
}

provider "huaweicloud" {
  region = "cn-north-4"
}

variable "solution_name" {
  default     = "openhands"
  description = "解决方案名称，4-24个字符，支持小写字母、数字、-（中划线），必须以小写字母开头。"
  type        = string
  nullable    = false
}

variable "ecs_flavor" {
  default     = "x1.2u.4g"
  description = "云服务器实例规格，x1.2u.4g（2vCPUs 4GiB）推荐。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^x1\\.([1-9]|1[0-6])u\\.([1-9][0-9]{0,1}|1[0-2][0-8])g$", var.ecs_flavor))
    error_message = "规格格式无效，示例：x1.2u.4g"
  }
}

variable "ecs_password" {
  default     = ""
  description = "云服务器密码，8-26位，至少包含大写字母、小写字母、数字和特殊字符中的三种。"
  type        = string
  sensitive   = true
  nullable    = false
}

variable "system_disk_size" {
  default     = 60
  description = "系统盘大小（GB），高IO类型，取值范围：40-1024。默认：60。"
  type        = number
  nullable    = false
  validation {
    condition     = var.system_disk_size >= 40 && var.system_disk_size <= 1024
    error_message = "系统盘大小必须在40到1024之间。"
  }
}

variable "bandwidth_size" {
  default     = 300
  description = "弹性公网带宽（Mbit/s），按流量计费，取值范围：1-300。默认：300。"
  type        = number
  nullable    = false
  validation {
    condition     = var.bandwidth_size >= 1 && var.bandwidth_size <= 300
    error_message = "带宽必须在1到300之间。"
  }
}

variable "charging_mode" {
  default     = "postPaid"
  description = "计费模式：postPaid（按需计费）或 prePaid（包年包月）。默认：postPaid。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "必须为 postPaid 或 prePaid。"
  }
}

variable "charging_unit" {
  default     = "month"
  description = "订购周期类型：month（月）或 year（年），仅 prePaid 模式生效。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "必须为 month 或 year。"
  }
}

variable "charging_period" {
  default     = 1
  description = "订购周期，1-9（月）或 1-3（年），仅 prePaid 模式生效。"
  type        = number
  nullable    = false
  validation {
    condition     = var.charging_period >= 1 && var.charging_period <= 9
    error_message = "周期必须在1到9之间。"
  }
}

variable "obs_base_url" {
  default     = "https://tp-00940108.obs.cn-north-4.myhuaweicloud.com"
  description = "OBS 脚本分发桶地址，用于下载部署脚本。"
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
  description       = "允许ping测试连通性"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "openhands_web" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "OpenHands Web UI端口"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 3000
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Cloud Shell SSH登录"
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
  system_disk_type            = "SAS"
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
    app = "OpenHands"
  }
  user_data = "#!/bin/bash\necho 'root:${var.ecs_password}' | chpasswd\nLOG=\"/var/log/openhands-bootstrap.log\"\nexec > >(tee -a \"$LOG\") 2>&1\necho \"[$(date)] Bootstrap: start\"\ncurl -fsSL -o /tmp/install_openhands.sh \"${var.obs_base_url}/openhands/cn/cn-north-4/standard/install_openhands.sh\"\nchmod +x /tmp/install_openhands.sh\nbash /tmp/install_openhands.sh\nRC=$?\necho \"[$(date)] Bootstrap: finished (exit=$RC)\"\nexit $RC"
}

output "access_info" {
  description = "部署访问信息"
  value       = <<-EOT
等待约10分钟部署完成，然后访问 OpenHands Web UI：

Web UI: http://${huaweicloud_vpc_eip.vpc_eip.address}:3000/
SSH: ssh root@${huaweicloud_vpc_eip.vpc_eip.address}

首次使用需在 Web UI 中配置 LLM API Key。

日志: /var/log/openhands-install.log
EOT
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}

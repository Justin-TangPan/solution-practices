terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">=1.67.1"
    }
  }
}

provider "huaweicloud" {
  region = "cn-north-4"
}

variable "solution_name" {
  default     = "deploying-openhands-demo"
  description = "解决方案名称，4-24字符，小写字母/数字/中划线，小写字母开头。"
  type        = string
  nullable    = false
}

variable "ecs_flavor" {
  default     = "x1.2u.4g"
  description = "Flexus X 实例规格。2vCPUs 4GiB 及以上。"
  type        = string
  nullable    = false
}

variable "ecs_password" {
  default     = ""
  description = "云服务器密码，8-26位，含大小写字母+数字+特殊字符三种。"
  type        = string
  sensitive   = true
  nullable    = true
}

variable "system_disk_size" {
  default     = 60
  description = "系统盘(GB)，高IO，40-1024。"
  type        = number
  nullable    = false
}

variable "bandwidth_size" {
  default     = 10
  description = "弹性公网带宽(Mbit/s)，按流量计费。"
  type        = number
  nullable    = false
}

variable "charging_mode" {
  default     = "postPaid"
  description = "计费模式：postPaid（按需）/prePaid（包年包月）。"
  type        = string
  nullable    = false
}

variable "charging_unit" {
  default     = "month"
  description = "订购周期：month/year。"
  type        = string
  nullable    = false
}

variable "charging_period" {
  default     = 1
  description = "订购周期数。"
  type        = number
  nullable    = false
}

variable "obs_base_url" {
  default     = "https://tp-00940108.obs.cn-south-1.myhuaweicloud.com"
  description = "OBS 脚本分发桶地址，用于下载部署脚本。"
  type        = string
  nullable    = false
}

data "huaweicloud_images_image" "Ubuntu" {
  most_recent = true
  name        = "Ubuntu 22.04 server 64bit"
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
  name = "${var.solution_name}-secgroup"
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
  description       = "OpenHands Web UI"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 3000
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Cloud Shell SSH"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 22
  remote_ip_prefix  = "121.36.59.153/32"
}

resource "huaweicloud_vpc_eip" "vpc_eip" {
  name = "${var.solution_name}-eip"
  bandwidth {
    name        = "${var.solution_name}-bandwidth"
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
    app = "_sac_openhands"
  }
  user_data = "#!/bin/bash\necho 'root:${var.ecs_password}' | chpasswd\nLOG=\"/var/log/openhands-bootstrap.log\"\nexec > >(tee -a \"$LOG\") 2>&1\necho \"[$(date)] Bootstrap: start\"\ncurl -fsSL -o /tmp/install_openhands.sh \"${var.obs_base_url}/install_openhands.sh\"\nchmod +x /tmp/install_openhands.sh\nbash /tmp/install_openhands.sh\nRC=$?\necho \"[$(date)] Bootstrap: finished (exit=$RC)\"\nexit $RC"
}

output "access_instructions" {
  description = "OpenHands 使用说明"
  value       = "部署完成后（约10分钟），在浏览器访问 http://${huaweicloud_vpc_eip.vpc_eip.address}:3000/ 进入 OpenHands Web UI。SSH: ssh root@${huaweicloud_vpc_eip.vpc_eip.address}，部署日志：/var/log/openhands-install.log"
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}

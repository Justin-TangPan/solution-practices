# ============================================================
# OpenHuman 云端开发环境 — 主资源编排
# 架构: VPC + 子网 + 安全组 + EIP + Flexus X 实例
# ============================================================

# ---------- 查询可用区 ----------
data "huaweicloud_availability_zones" "main" {}

data "huaweicloud_compute_flavors" "main" {
  availability_zone = var.availability_zone
  performance_type  = "normal"
  cpu_core_count    = 2
  memory_size       = 4
}

# ---------- VPC 网络 ----------
resource "huaweicloud_vpc" "main" {
  name = "${var.resource_prefix}-vpc"
  cidr = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "main" {
  name       = "${var.resource_prefix}-subnet"
  cidr       = var.subnet_cidr
  vpc_id     = huaweicloud_vpc.main.id
  gateway_ip = cidrhost(var.subnet_cidr, 1)
}

# ---------- 安全组 ----------
resource "huaweicloud_networking_secgroup" "main" {
  name        = "${var.resource_prefix}-secgroup"
  description = "OpenHuman dev environment security group"
}

# SSH
resource "huaweicloud_networking_secgroup_rule" "allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

# Ollama API（可选，按需开启）
resource "huaweicloud_networking_secgroup_rule" "allow_ollama" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 11434
  port_range_max    = 11434
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

# ---------- 弹性公网 IP ----------
resource "huaweicloud_vpc_eip" "main" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.resource_prefix}-bandwidth"
    size        = var.bandwidth_size
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

# ---------- Flexus X 实例 ----------
data "huaweicloud_images_image" "main" {
  name        = var.image_id
  most_recent = true
}

resource "huaweicloud_compute_instance" "main" {
  name              = "${var.resource_prefix}-server"
  flavor_id         = data.huaweicloud_compute_flavors.main.flavors[0].id
  image_id          = data.huaweicloud_images_image.main.id
  availability_zone = var.availability_zone
  security_group_id = huaweicloud_networking_secgroup.main.id
  subnet_id         = huaweicloud_vpc_subnet.main.id
  admin_pass        = var.ecs_password

  system_disk_type = "SAS"
  system_disk_size = var.system_disk_size

  charging_mode = var.charging_mode

  user_data = filebase64("${path.module}/userdata/setup_openhuman_dev.sh")

  tags = {
    Name       = "${var.resource_prefix}-server"
    managed_by = "rfs"
    owner      = "solution"
    app        = "openhuman-dev-env"
  }
}

# EIP 绑定
resource "huaweicloud_vpc_eip_associate" "main" {
  public_ip   = huaweicloud_vpc_eip.main.address
  instance_id = huaweicloud_compute_instance.main.id
}

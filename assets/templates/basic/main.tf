# 网络资源
resource "huaweicloud_vpc" "main" {
  name = var.vpc_name
  cidr = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "main" {
  name       = var.subnet_name
  cidr       = var.subnet_cidr
  vpc_id     = huaweicloud_vpc.main.id
  gateway_ip = cidrhost(var.subnet_cidr, 1)
}

resource "huaweicloud_networking_secgroup" "main" {
  name        = "${var.ecs_name}-secgroup"
  description = "Solution security group"
}

resource "huaweicloud_networking_secgroup_rule" "allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

resource "huaweicloud_networking_secgroup_rule" "allow_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

resource "huaweicloud_networking_secgroup_rule" "allow_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

# 弹性公网 IP
resource "huaweicloud_vpc_eip" "main" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.ecs_name}-bandwidth"
    size        = var.bandwidth_size
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

# ECS 实例
resource "huaweicloud_compute_instance" "main" {
  name              = var.ecs_name
  flavor_id         = var.ecs_flavor
  image_id          = var.image_id
  availability_zone = var.availability_zone
  security_group_id = huaweicloud_networking_secgroup.main.id
  subnet_id         = huaweicloud_vpc_subnet.main.id
  admin_pass        = var.ecs_password

  eip_id = huaweicloud_vpc_eip.main.id

  tags = {
    Name        = var.ecs_name
    managed_by  = "rfs"
    owner       = "solution"
  }
}

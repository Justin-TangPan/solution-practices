#======================================
# 网络资源
#======================================
resource "huaweicloud_vpc" "main" {
  name = "${var.web_name}-vpc"
  cidr = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "main" {
  name       = "${var.web_name}-subnet"
  cidr       = var.subnet_cidr
  vpc_id     = huaweicloud_vpc.main.id
  gateway_ip = cidrhost(var.subnet_cidr, 1)
}

resource "huaweicloud_networking_secgroup" "ecs" {
  name        = "${var.web_name}-ecs-secgroup"
  description = "ECS security group"
}

# 安全组规则：Web 端口
resource "huaweicloud_networking_secgroup_rule" "allow_web" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.ecs.id
}

resource "huaweicloud_networking_secgroup_rule" "allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.ecs.id
}

resource "huaweicloud_networking_secgroup" "rds" {
  name        = "${var.web_name}-rds-secgroup"
  description = "RDS security group"
}

resource "huaweicloud_networking_secgroup_rule" "rds_mysql" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = huaweicloud_networking_secgroup.rds.id
}

#======================================
# 弹性公网 IP
#======================================
resource "huaweicloud_vpc_eip" "main" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.web_name}-bandwidth"
    size        = var.bandwidth_size
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

#======================================
# ECS 实例
#======================================
resource "huaweicloud_compute_instance" "main" {
  name              = "${var.web_name}-server"
  flavor_id         = var.ecs_flavor
  image_id          = var.image_id
  availability_zone = var.availability_zone
  security_group_id = huaweicloud_networking_secgroup.ecs.id
  subnet_id         = huaweicloud_vpc_subnet.main.id
  admin_pass        = var.ecs_password

  user_data = filebase64("${path.module}/userdata/install_web.sh")

  tags = {
    Name        = "${var.web_name}-server"
    managed_by  = "rfs"
    owner       = "solution"
  }
}

resource "huaweicloud_vpc_eip_associate" "main" {
  public_ip  = huaweicloud_vpc_eip.main.address
  instance_id = huaweicloud_compute_instance.main.id
}

#======================================
# RDS 实例
#======================================
resource "huaweicloud_rds_instance" "main" {
  name              = "${var.web_name}-db"
  flavor            = var.rds_flavor
  vpc_id            = huaweicloud_vpc.main.id
  subnet_id         = huaweicloud_vpc_subnet.main.id
  security_group_id = huaweicloud_networking_secgroup.rds.id
  availability_zone = [var.availability_zone_rds]

  db {
    type     = "MySQL"
    version  = "8.0"
    password = var.db_password
  }

  volume {
    type = "ULTRAHIGH"
    size = 40
  }

  tags = {
    Name        = "${var.web_name}-db"
    managed_by  = "rfs"
    owner       = "solution"
  }
}

#======================================
# OBS 存储桶（静态文件）
#======================================
resource "huaweicloud_obs_bucket" "main" {
  bucket        = "${var.web_name}-static"
  storage_class = "STANDARD"
  acl           = "private"

  tags = {
    managed_by = "rfs"
    owner      = "solution"
  }
}

#======================================
# 输出
#======================================
output "web_url" {
  description = "Web 应用访问地址"
  value       = "http://${huaweicloud_vpc_eip.main.address}"
}

output "db_host" {
  description = "RDS 数据库连接地址"
  value       = huaweicloud_rds_instance.main.private_ips[0]
}

output "db_name" {
  description = "初始数据库名称"
  value       = var.db_name
}

output "ecs_id" {
  description = "ECS 实例 ID"
  value       = huaweicloud_compute_instance.main.id
}

output "obs_bucket" {
  description = "OBS 桶名称"
  value       = huaweicloud_obs_bucket.main.bucket
}

#======================================
# 数据源
#======================================
data "huaweicloud_availability_zones" "main" {}

#======================================
# VPC 网络
#======================================
resource "huaweicloud_vpc" "main" {
  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "zone1" {
  name       = "${var.cluster_name}-subnet-1"
  cidr       = var.subnet_cidr_1
  vpc_id     = huaweicloud_vpc.main.id
  gateway_ip = cidrhost(var.subnet_cidr_1, 1)
}

resource "huaweicloud_vpc_subnet" "zone2" {
  name       = "${var.cluster_name}-subnet-2"
  cidr       = var.subnet_cidr_2
  vpc_id     = huaweicloud_vpc.main.id
  gateway_ip = cidrhost(var.subnet_cidr_2, 1)
}

#======================================
# 安全组
#======================================
resource "huaweicloud_networking_secgroup" "ecs" {
  name        = "${var.cluster_name}-ecs-secgroup"
  description = "ECS cluster security group"
}

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
  name        = "${var.cluster_name}-rds-secgroup"
  description = "RDS security group"
}

resource "huaweicloud_networking_secgroup_rule" "rds_mysql" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = huaweicloud_networking_secgroup.rds.id
}

#======================================
# ELB 负载均衡
#======================================
resource "huaweicloud_elb_loadbalancer" "main" {
  name          = "${var.cluster_name}-elb"
  description   = "Web cluster load balancer"
  vpc_id        = huaweicloud_vpc.main.id
  ipv4_subnet_id = huaweicloud_vpc_subnet.zone1.id

  bandwidth {
    name        = "${var.cluster_name}-elb-bandwidth"
    size        = var.elb_bandwidth
    share_type  = "PER"
    charge_mode = "traffic"
  }

  tags = {
    Name       = "${var.cluster_name}-elb"
    managed_by = "rfs"
    owner      = "solution"
  }
}

resource "huaweicloud_lb_listener" "http" {
  name            = "${var.cluster_name}-http-listener"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = huaweicloud_elb_loadbalancer.main.id
}

resource "huaweicloud_lb_pool" "web" {
  name        = "${var.cluster_name}-web-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = huaweicloud_lb_listener.http.id
}

resource "huaweicloud_lb_monitor" "web" {
  protocol    = "HTTP"
  interval    = 5
  timeout     = 3
  max_retries = 3
  pool_id     = huaweicloud_lb_pool.web.id
}

#======================================
# ECS 集群
#======================================
resource "huaweicloud_compute_instance" "cluster" {
  count = var.ecs_count

  name              = "${var.cluster_name}-ecs-${count.index + 1}"
  flavor_id         = var.ecs_flavor
  image_id          = var.image_id
  availability_zone = count.index == 0 ? var.availability_zone_1 : var.availability_zone_2
  security_group_id = huaweicloud_networking_secgroup.ecs.id
  subnet_id         = count.index == 0 ? huaweicloud_vpc_subnet.zone1.id : huaweicloud_vpc_subnet.zone2.id
  admin_pass        = var.ecs_password

  user_data = filebase64("${path.module}/userdata/install_app.sh")

  tags = {
    Name       = "${var.cluster_name}-ecs-${count.index + 1}"
    managed_by = "rfs"
    owner      = "solution"
  }
}

# 将 ECS 加入 ELB 后端池
resource "huaweicloud_lb_member" "cluster" {
  count         = var.ecs_count
  address       = huaweicloud_compute_instance.cluster[count.index].access_ip_v4
  protocol_port = 80
  pool_id       = huaweicloud_lb_pool.web.id
  subnet_id     = count.index == 0 ? huaweicloud_vpc_subnet.zone1.id : huaweicloud_vpc_subnet.zone2.id
}

#======================================
# RDS 实例
#======================================
resource "huaweicloud_rds_instance" "main" {
  name              = "${var.cluster_name}-db"
  flavor            = var.rds_flavor
  vpc_id            = huaweicloud_vpc.main.id
  subnet_id         = huaweicloud_vpc_subnet.zone1.id
  security_group_id = huaweicloud_networking_secgroup.rds.id
  availability_zone = [var.availability_zone_1, var.availability_zone_2]

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
    Name       = "${var.cluster_name}-db"
    managed_by = "rfs"
    owner      = "solution"
  }
}

#======================================
# OBS 存储桶
#======================================
resource "huaweicloud_obs_bucket" "main" {
  bucket        = "${var.cluster_name}-static"
  storage_class = "STANDARD"
  acl           = "private"

  tags = {
    managed_by = "rfs"
    owner      = "solution"
  }
}

output "ecs_id" {
  description = "ECS 实例 ID"
  value       = huaweicloud_compute_instance.main.id
}

output "ecs_public_ip" {
  description = "ECS 公网 IP"
  value       = huaweicloud_vpc_eip.main.address
}

output "vpc_id" {
  description = "VPC ID"
  value       = huaweicloud_vpc.main.id
}

output "subnet_id" {
  description = "子网 ID"
  value       = huaweicloud_vpc_subnet.main.id
}

output "web_url" {
  description = "应用访问地址"
  value       = "http://${huaweicloud_vpc_eip.main.address}"
}

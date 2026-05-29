output "web_url" {
  description = "Web 应用访问地址"
  value       = "http://${huaweicloud_vpc_eip.main.address}"
}

output "rds_host" {
  description = "RDS 数据库地址"
  value       = huaweicloud_rds_instance.main.private_ips[0]
}

output "rds_database" {
  description = "初始数据库名称"
  value       = var.db_name
}

output "obs_bucket" {
  description = "OBS 存储桶"
  value       = huaweicloud_obs_bucket.main.bucket
}

output "ecs_id" {
  description = "ECS 实例 ID"
  value       = huaweicloud_compute_instance.main.id
}

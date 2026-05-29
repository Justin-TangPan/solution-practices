output "elb_address" {
  description = "ELB 公网地址（应用入口）"
  value       = huaweicloud_elb_loadbalancer.main.ipv4_address
}

output "web_url" {
  description = "应用访问地址"
  value       = "http://${huaweicloud_elb_loadbalancer.main.ipv4_address}"
}

output "ecs_ids" {
  description = "ECS 实例 ID 列表"
  value       = [for i in huaweicloud_compute_instance.cluster : i.id]
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
  description = "OBS 桶名称"
  value       = huaweicloud_obs_bucket.main.bucket
}

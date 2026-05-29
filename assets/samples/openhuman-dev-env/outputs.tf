# ============================================================
# OpenHuman 云端开发环境 — 输出定义
# ============================================================

output "ssh_access" {
  description = "SSH 连接命令"
  value       = "ssh root@${huaweicloud_vpc_eip.main.address}"
}

output "public_ip" {
  description = "ECS 公网 IP"
  value       = huaweicloud_vpc_eip.main.address
}

output "ecs_id" {
  description = "ECS 实例 ID"
  value       = huaweicloud_compute_instance.main.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = huaweicloud_vpc.main.id
}

output "ollama_api" {
  description = "Ollama API 地址（供 OpenHuman 桌面端连接）"
  value       = "http://${huaweicloud_vpc_eip.main.address}:11434"
}

output "project_dir" {
  description = "OpenHuman 项目路径"
  value       = "/opt/openhuman"
}

output "setup_log" {
  description = "部署日志查看命令"
  value       = "tail -f /var/log/setup-openhuman.log"
}

output "quick_start" {
  description = "快速开始指引"
  value = <<-EOF
    ┌───────────────────────────────────────────────────┐
    │  OpenHuman 云端开发环境已就绪                       │
    ├───────────────────────────────────────────────────┤
    │  1. SSH 连接: ssh root@${huaweicloud_vpc_eip.main.address}  │
    │  2. 进入项目: cd /opt/openhuman                    │
    │  3. 启动开发: pnpm dev                             │
    │  4. Ollama API: http://${huaweicloud_vpc_eip.main.address}:11434 │
    │                                                   │
    │  注意：这是一个开发环境，非生产部署。                  │
    │  OpenHuman 是桌面应用，需通过 SSH 进入开发。         │
    └───────────────────────────────────────────────────┘
  EOF
}

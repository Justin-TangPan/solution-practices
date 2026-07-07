# 安全审计规则（公共参考文档）

> 本文档定义了 SAC 项目安全审计的检查规则。sac-security Agent 通过引用本文档执行审计。

| ID | 严重度 | 规则 | 检查命令 |
|----|--------|------|----------|
| SEC-001 | critical | 安装脚本不得硬编码 AK/SK | `grep -inE '(access_key\|secret_key\|AKID\|SKID\|ak\\s*=\|sk\\s*=)' install_*.sh` |
| SEC-002 | critical | 安装脚本不得硬编码 API Key | `grep -inE '(api.?key\|apikey\|token\\s*=\|master.?key)' install_*.sh` |
| SEC-003 | high | 安全组不得开放高危端口到 0.0.0.0/0 | `grep -A2 'remote_ip_prefix.*0.0.0.0/0' deploying-* \| grep -E '(22\|3306\|5432\|6379\|27017)'` |
| SEC-004 | high | SSH 端口仅限 Cloud Shell IP | `grep -B2 'ports.*22' deploying-* \| grep -c '121.36.59.153/32'` |
| SEC-005 | medium | cn 站点安装脚本不应包含 docker login（SWR 镜像应公开读，无需认证拉取） | `grep -c 'docker login' install_*.sh` |
| SEC-006 | medium | 数据库密码通过环境变量传入 | `grep -E '(POSTGRES_PASSWORD\|DB_PASSWORD\|REDIS_PASSWORD)' docker-compose.yaml` |
| SEC-007 | low | 容器不以 privileged 模式运行 | `grep -c 'privileged: true' docker-compose.yaml` |
| SEC-008 | low | ECS 开启 hss + ces 监控 | `grep -c 'agent_list.*hss.*ces' deploying-*` |

# 集群部署模板

## 适用场景
高可用 Web 应用集群，包含 2×ECS + 1×ELB + 1×RDS + EIP。

## 文件清单

```
cluster/
├── .extension
├── versions.tf
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── userdata/
│   └── install_app.sh
└── README.md
```

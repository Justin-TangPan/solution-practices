# Web 应用部署模板

## 适用场景
新建 VPC，部署 Web 应用（ECS + ELB + RDS + Redis）。

## 文件清单

```
web-application/
├── .extension
├── versions.tf
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── userdata/
│   ├── install_web.sh
│   └── configure_app.sh
└── README.md
```

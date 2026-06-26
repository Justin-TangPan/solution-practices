# OBS 存储规范（公共参考文档）

> 本文档是 SAC 项目的 OBS 存储规范权威来源。各 Skill 通过引用本文档避免重复。

## OBS 目录结构

按区域组 + 具体区域分层：

```
obs://{bucket}/{project}/
├── cn/
│   ├── cn-north-4/standard/    # 华北-北京四
│   └── ap-southeast-1/         # 中国-香港（归属 cn 站点）
│       ├── standard/
│       └── ha/
└── intl/
    ├── ap-southeast-3/standard/    # 亚太-新加坡
    ├── ap-southeast-2/standard/    # 亚太-曼谷
    ├── af-south-1/standard/        # 非洲-约翰内斯堡
    ├── af-north-1/standard/        # 非洲-开罗
    ├── tr-west-1/standard/         # 土耳其-伊斯坦布尔
    ├── la-north-2/standard/        # 拉美-墨西哥城2
    └── sa-brazil-1/standard/       # 拉美-圣保罗
```

## 环境区分

| 环境 | 桶 | 用途 | 操作人 |
|------|-----|------|--------|
| 测试 | `tp-00940108` | 开发阶段上传测试 | AI |
| 生产 | 用户指定 | 最终上线 | 用户亲自上传 |

## RFS URL 格式

```
https://console-intl.huaweicloud.com/rf/?region={region}&locale=en-us#/console/stack/stackCreate?templateUrl={TF_URL}&stackName={name}&stackDescription={desc}
```

**注意：** RFS URL 中的 `templateUrl` 指向生产 OBS 桶，不是测试桶。

## OBS 上传操作

使用 Python SDK 上传文件：

```python
from obs import ObsClient
c = ObsClient(
    access_key_id='AK',
    secret_access_key='SK',
    server='https://obs.cn-south-1.myhuaweicloud.com',
    path_style=False
)
c.putFile('bucket-name', 'remote-name.sh', '/local/path.sh')
c.close()
```

每次方案需上传：
1. `install_{app}.sh` — 安装脚本
2. `deploying-{app}.tf` — RFS 模板
3. `{app}-platform.zip` — 项目归档包

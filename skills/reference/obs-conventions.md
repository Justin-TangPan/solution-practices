# OBS 存储规范（公共参考文档）

> 本文档是 SAC 项目的 OBS 存储规范权威来源。各 Skill 通过引用本文档避免重复。

## OBS 目录结构

按区域组 + 具体区域分层：

```
obs://{bucket}/{project}/
├── cn/
│   └── cn-north-4/standard/    # 华北-北京四
└── intl/
    ├── ap-southeast-1/             # 中国-香港（归属 intl 国际站）
    │   ├── standard/
    │   └── ha/
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
| 生产 | 用户指定 | 最终上线 | 用户亲自上传 |

> 测试桶信息仅保存在本地开发记忆中，不提交到公开仓库。

## TF 模板规范（标准内联，OBS 地址不做用户参数）

SAC 标准实践默认采用内联 user_data：`.tf` 模板自包含基础设施和应用部署逻辑，不依赖 OBS-hosted `install_*.sh`。参考 LiteLLM、Supabase 这类实践，不做分布式脚本。

外置脚本属于例外模式。只有用户明确要求或存在必须热更新脚本的技术约束时，才在 user_data 中下载 OBS 脚本。

**`obs_base_url` / 桶地址 / 脚本 URL 必须用 `locals` 块或直接内联在 `user_data` 里，禁止用 `variable`。**

生产 OBS 桶地址是公开发布信息，不是安全风险点。但 `variable` 会进 RFS 控制台参数面，客户一键部署时会看到"OBS 桶地址"这种实现细节，影响参数面清晰度。`locals` 不进参数面，TF 也不报错。

```hcl
# ✅ 正确：locals，不进参数面
locals {
  obs_base_url = "https://{PRODUCTION_BUCKET}.obs.{region}.myhuaweicloud.com/{path}"
}
user_data = "...wget -P /home/ ${local.obs_base_url}/litellm/intl/af-south-1/standard/scripts/install_litellm.sh..."

# ✅ 也正确：release/ 模板直接内联市场桶全 URL
user_data = "...wget -P /home/ https://documentation-samples-11.obs.af-south-1.myhuaweicloud.com/.../standard/install_litellm.sh..."

# ❌ 错误：variable 会展示给客户
variable "obs_base_url" { default = "..." }
user_data = "...wget -P /home/ ${var.obs_base_url}/..."
```

例外脚本模式下，`user_data` 里 wget/curl 的脚本路径必须与桶内对象 key 完全一致；如果仓库采用 `scripts/` 层，路径也必须包含 `scripts/`。禁止 `litellm-hk` 这类把 hk 当站点的遗留路径。

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

标准方案需上传：
1. `deploying-{app}.tf` — RFS 模板（内联 user_data）
2. `{app}.zip` — 项目归档包

例外脚本模式才额外上传 `install_{app}.sh`。`manifest.json` 不是 SAC 标准交付物；只有测试索引或外部工具明确需要时才可临时上传。

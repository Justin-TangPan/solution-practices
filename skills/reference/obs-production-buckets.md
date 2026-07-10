# OBS 生产发布桶映射表（公开发布参考）

> 本文档是 SAC 项目生产 OBS 桶与区域代码的权威映射。
> 生产桶地址用于公开解决方案发布，可对外公布，不作为安全风险点。测试桶、AK/SK、上传凭证仍不得提交。

SAC 公开发布用的 OBS 桶按区域一对一划分，桶名 `documentation-samples[-N]`，endpoint 与桶所在区域一致（`{bucket}.obs.{region}.myhuaweicloud.com`）。

| 桶名 | 区域显示名 | 区域代码 |
|------|-----------|---------|
| documentation-samples | 华北-北京四 | cn-north-4 |
| documentation-samples-2 | 华南-广州 | cn-south-1 |
| documentation-samples-3 | 华东-上海一 | cn-east-3 |
| documentation-samples-4 | 亚太-新加坡 | ap-southeast-3 |
| documentation-samples-5 | 中国-香港 | ap-southeast-1 |
| documentation-samples-6 | 亚太-曼谷 | ap-southeast-2 |
| documentation-samples-8 | 土耳其-伊斯坦布尔 | tr-west-1 |
| documentation-samples-9 | 西南-贵阳一 | cn-southwest-2 |
| documentation-samples-10 | af-north-1 | af-north-1 |
| documentation-samples-11 | 南非-约翰内斯堡 | af-south-1 |
| documentation-samples-12 | 中东-利雅得 | me-east-1 |
| documentation-samples-13 | 拉美-墨西哥城二 | la-north-2 |
| documentation-samples-14 | 拉美-圣保罗一 | sa-brazil-1 |
| documentation-samples-15 | 拉美-圣地亚哥 | la-south-2 |
| documentation-samples-16 | cn-east-4 | cn-east-4 |
| documentation-samples-17 | 华北-乌兰察布一 | cn-north-9 |
| documentation-samples-18 | 亚太-雅加达 | ap-southeast-4 |

## 使用方法

生成某区域 url.txt / `obs_base_url` 时，查此表取该区域对应桶名，endpoint 用 `obs.{region}.myhuaweicloud.com`。

路径统一：`solution-as-code-publicbucket/solution-as-code-module/{solution-slug}/{lang}/{standard|ha}/{filename}`

## 测试桶

> 测试桶信息仅保存在本地开发记忆中，不提交到公开仓库。

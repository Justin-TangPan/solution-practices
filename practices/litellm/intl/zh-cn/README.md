# LiteLLM 国际站 — 中文版模板（zh-cn）

本目录为 `intl` 国际站的中文注释模板层，与 `intl/en-us/` 对应。

## 现状

当前为**空占位**。`intl/en-us/` 已有 8 个区域的英文版模板（af-north-1、af-south-1、ap-southeast-1、ap-southeast-2、ap-southeast-3、la-north-2、sa-brazil-1、tr-west-1）。

## 计划

后续为每个区域生成 `intl/zh-cn/{region}/standard/terraform/litellm-standard-{region}.tf(.json)`，内容与 `en-us` 版**完全一致**，仅把 user_data 内的 bash 注释、Terraform description 翻译为中文。

## 目录约定

```
intl/zh-cn/{region}/standard/terraform/litellm-standard-{region}.tf(.json)
intl/zh-cn/{region}/ha/.extension   (如需)
```

生成时参考 `intl/en-us/{region}/` 对应文件，逐区域替换注释语言。

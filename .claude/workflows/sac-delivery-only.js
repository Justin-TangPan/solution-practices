export const meta = {
  name: 'sac-delivery-only',
  description: 'SAC 交付流程：从 practices/ 打包到 release/，生成 URL 清单',
  phases: [
    { title: 'Prepare', detail: '整理与预置' },
    { title: 'Package', detail: '打包归档' },
    { title: 'Generate URLs', detail: '生成 URL 清单' },
  ],
}

const PROJECT = args.project
const REGIONS = args.regions || ['cn', 'hk']

log(`📦 SAC 交付打包启动：${PROJECT}`)

phase('Prepare')
const prepResult = await agent(`
你是一名 SAC 交付 Agent（参考 .claude/agents/sac-delivery.json）。

项目：${PROJECT}
区域：${REGIONS.join(', ')}

## 任务
1. 创建 release/${PROJECT}/ 目录
2. 从 practices/${PROJECT}/ 复制文件到对应区域子目录
3. 预置 templateUrl 指向生产 OBS 路径（placeholder: {bucket} 替换为目标桶名）

输出目录结构。
`, { schema: {
  type: 'object',
  properties: { release_dir: { type: 'string' }, regions_ready: { type: 'array', items: { type: 'string' } } },
  required: ['release_dir', 'regions_ready'],
}})

phase('Generate URLs')
const urlResult = await agent(`
你是一名 SAC 交付 Agent。

项目：${PROJECT}
区域：${REGIONS.join(', ')}

## 任务
为每个区域生成 URL 清单文件 release/${PROJECT}/url.txt。

格式：
# --- {region} ({region_name}) ---
TF:https://{bucket}.obs.{region}.myhuaweicloud.com/{path}/deploying-${PROJECT}.tf
sh:https://{bucket}.obs.{region}.myhuaweicloud.com/{path}/install_${PROJECT}.sh
RFS_intl:https://console-intl.huaweicloud.com/rf/?region={region}&locale=en-us#/console/stack/stackCreate?templateUrl={TF_URL}&stackName=${PROJECT}&stackDescription=${PROJECT}

区域代码映射：
- cn → cn-north-4 (Beijing)
- hk → ap-southeast-1 (Hong Kong)
- intl → 多区域（生成 url_ha.txt 和 url_standard.txt）

输出 URL 文件路径。
`, { schema: {
  type: 'object',
  properties: { url_files: { type: 'array', items: { type: 'string' } } },
  required: ['url_files'],
}})

phase('Package')
const archiveResult = await agent(`
创建 release/${PROJECT}/${PROJECT}.zip 归档包。
输出归档文件路径。
`, { schema: {
  type: 'object',
  properties: { archive_file: { type: 'string' }, size_bytes: { type: 'number' } },
  required: ['archive_file'],
}})

log(`✅ 交付完成：${PROJECT}`)
log(`   发布目录：${prepResult.release_dir}`)
log(`   URL 文件：${urlResult.url_files.join(', ')}`)
log(`   归档包：${archiveResult.archive_file} (${Math.round(archiveResult.size_bytes / 1024)} KB)`)

return {
  project: PROJECT,
  release_dir: prepResult.release_dir,
  url_files: urlResult.url_files,
  archive_file: archiveResult.archive_file,
}

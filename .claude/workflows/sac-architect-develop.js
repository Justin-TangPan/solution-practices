export const meta = {
  name: 'sac-architect-develop',
  description: 'SAC 架构+开发：快速原型，跳过测试/安全/文档/交付，架构师设计后直接开发',
  phases: [
    { title: 'Architect', detail: '方案设计' },
    { title: 'Develop', detail: '快速开发' },
  ],
}

const PROJECT = args.project
const REGIONS = args.regions
const DESCRIPTION = args.description

log(`🚀 SAC 快速原型启动：${PROJECT}`)

// Phase 1: 架构师
phase('Architect')
const architectResult = await agent(`
你是一名 SAC 架构师 Agent。项目：${PROJECT}，区域：${REGIONS.join(', ')}，描述：${DESCRIPTION}

请输出：
1. 技术可行性分析
2. 架构设计方案（ASCII 图 + 资源清单）
3. 决策点确认（格式/地域/语言/安装策略/容器化）
4. 变量设计表（7 标准变量 + 应用专属变量）
`, { schema: {
  type: 'object',
  properties: {
    architecture: { type: 'string' },
    decisions: { type: 'object', properties: {
      template_format: { type: 'string' },
      install_strategy: { type: 'string' },
      language: { type: 'string' },
      containerization: { type: 'string' },
    }, required: ['template_format', 'install_strategy', 'language', 'containerization'] },
    variables: { type: 'array' },
  },
  required: ['architecture', 'decisions', 'variables'],
}})

// Phase 2: 开发（按区域并行）
phase('Develop')
const devResults = await pipeline(
  REGIONS,
  async (region) => {
    const is_cn = region === 'cn'
    const l = is_cn ? 'zh' : 'en'
    return await agent(`
你是一名 SAC 开发 Agent。在 practices/${PROJECT}/${region}/ 下创建：
1. terraform/deploying-${PROJECT}.tf
2. scripts/install_${PROJECT}.sh
3. scripts/docker-compose.yaml（如适用）
4. .extension

决策：${JSON.stringify(architectResult.decisions)}
变量：${JSON.stringify(architectResult.variables)}

${is_cn ? '国内版：Docker 从 mirrors.huaweicloud.com，pip 用清华镜像' : '海外版：Docker 从 download.docker.com'}
`, { label: `dev:${region}`, schema: {
  type: 'object',
  properties: { files_created: { type: 'array', items: { type: 'string' } } },
  required: ['files_created'],
}})
  }
)

log(`✅ 快速原型完成：${PROJECT}`)
devResults.forEach(r => log(`   ${r.region}: ${r.files_created?.length || 0} 个文件`))

return { project: PROJECT, regions: REGIONS, decisions: architectResult.decisions, dev_results: devResults }

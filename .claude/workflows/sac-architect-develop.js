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
const architectResult = await agent({
  label: 'architect',
  agentType: 'sac-architect',
  prompt: `## 项目上下文
项目：${PROJECT}
区域：${REGIONS.join(', ')}
描述：${DESCRIPTION}

## 任务
1. 技术可行性分析
2. 架构设计方案（ASCII 图 + 资源清单）
3. 决策点确认（格式/地域/语言/安装策略/容器化）
4. 冻结参数合同（只保留有规则、官方或用户依据的变量）
5. 返回规则、精确参考模板、固定值、公网入口、允许文件和偏差`,
  schema: {
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
      rules_read: { type: 'array' },
      reference_templates: { type: 'array' },
      fixed_values: { type: 'object' },
      public_endpoints: { type: 'array' },
      allowed_artifacts: { type: 'array' },
      deviations: { type: 'array' },
    },
    required: ['architecture', 'decisions', 'variables', 'rules_read', 'reference_templates', 'fixed_values', 'public_endpoints', 'allowed_artifacts', 'deviations'],
  },
})

if (architectResult.deviations.some(item => item.requires_user_confirmation && !item.confirmed_by_user)) {
  throw new Error('Prototype development blocked by unapproved architecture deviations')
}

// Phase 2: 开发（按区域并行）
phase('Develop')
const devResults = await pipeline(
  REGIONS,
  async (region) => {
    const is_cn = region === 'cn' || region.startsWith('cn/')
    return await agent({
      label: `dev:${region}`,
      agentType: 'sac-developer',
      prompt: `## 项目上下文
项目：${PROJECT}，区域：${region}
${is_cn ? '源类型：国内（华为云镜像、PyPI镜像）' : '源类型：海外（官方源）'}

	按 sac-project-rules 的 site/locale/region/variant 目录模型，在 practices/${PROJECT}/ 下创建对应文件：
	1. <site>/<locale?>/<region>/<variant>/terraform/deploying-${PROJECT}.tf
	2. <site>/<locale?>/<region>/<variant>/scripts/install_${PROJECT}.sh（OBS 下载模式需要；全内联模式可省略 scripts/）
	3. <site>/<locale?>/<region>/<variant>/scripts/docker-compose.yaml（如适用）
	4. <site>/<locale?>/<region>/<variant>/.extension（当前质量门禁可选）

决策：${JSON.stringify(architectResult.decisions)}
变量：${JSON.stringify(architectResult.variables)}
固定值：${JSON.stringify(architectResult.fixed_values)}
公网入口：${JSON.stringify(architectResult.public_endpoints)}
允许文件：${JSON.stringify(architectResult.allowed_artifacts)}
禁止增加合同外变量、端口、代理层、requirements/lock 或外部下载。`,
      schema: {
        type: 'object',
        properties: { files_created: { type: 'array', items: { type: 'string' } } },
        required: ['files_created'],
      },
    })
  },
)

log(`✅ 快速原型完成：${PROJECT}`)
devResults.forEach(r => log(`   ${r.region}: ${r.files_created?.length || 0} 个文件`))

return { project: PROJECT, regions: REGIONS, decisions: architectResult.decisions, dev_results: devResults }

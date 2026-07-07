export const meta = {
  name: 'sac-full-pipeline',
  description: 'SAC 全流程：架构→开发→测试→安全审查→文档→交付，6 Agent 串行协同',
  phases: [
    { title: 'Architect', detail: '方案设计与技术评估' },
    { title: 'Develop', detail: '模板与脚本开发' },
    { title: 'Test & Security', detail: '验证与安全审查' },
    { title: 'Document', detail: '文档编写与生成' },
    { title: 'Deliver', detail: '发布打包与上线' },
  ],
}
// ============================================================================
// SAC 全流程工作流
// 6 个 Agent 依次协同：架构师 → 开发 → 测试 → 安全 → 文档 → 交付
// 各 Agent 角色定义和规则在 .claude/agents/ 中，通过 agentType 引用
// 本文件仅传递项目上下文，不重复 Agent 定义内容
// ============================================================================

const PROJECT = args.project          // e.g. "litellm"
const REGIONS = args.regions          // e.g. ["cn", "intl"]
const DESCRIPTION = args.description  // e.g. "Multi-model API Gateway"

log(`🚀 SAC 全流程启动：${PROJECT}`)
log(`   区域：${REGIONS.join(', ')}`)
log(`   描述：${DESCRIPTION}`)

// ============================================================================
// Phase 1: 架构师 — 方案设计与技术评估
// ============================================================================
phase('Architect')
log('🧠 架构师开始工作...')

const architectResult = await agent({
  label: 'architect',
  agentType: 'sac-architect',
  prompt: `## 项目上下文
项目：${PROJECT}
区域：${REGIONS.join(', ')}
描述：${DESCRIPTION}

## 任务
1. 技术可行性分析
2. 方案架构设计（单机标准版 vs 高可用版）
3. 决策点确认（模板格式、安装策略、语言、容器化、部署类型）
4. 变量设计（7个标准变量 + 应用专属变量）
5. 资源清单
6. 依赖清单`,
  schema: {
    type: 'object',
    properties: {
      feasibility: { type: 'string' },
      architecture: { type: 'string' },
      decisions: {
        type: 'object',
        properties: {
          template_format: { type: 'string', enum: ['hcl', 'json'] },
          install_strategy: { type: 'string', enum: ['inline', 'obs_download'] },
          language: { type: 'string', enum: ['zh', 'en'] },
          containerization: { type: 'string', enum: ['docker_compose', 'direct_install'] },
          deployment_type: { type: 'string', enum: ['standard', 'ha'] },
        },
        required: ['template_format', 'install_strategy', 'language', 'containerization', 'deployment_type'],
      },
      variables: { type: 'array', items: { type: 'object' } },
      resources: { type: 'array', items: { type: 'object' } },
      dependencies: { type: 'array', items: { type: 'string' } },
    },
    required: ['feasibility', 'architecture', 'decisions', 'variables', 'resources', 'dependencies'],
  },
})

log(`✅ 架构设计完成`)
log(`   格式：${architectResult.decisions.template_format}`)
log(`   安装：${architectResult.decisions.install_strategy}`)
log(`   语言：${architectResult.decisions.language}`)

// ============================================================================
// Phase 2: 开发 — 模板与脚本开发（按区域并行）
// ============================================================================
phase('Develop')
log('💻 开发 Agent 开始工作...')

const devResults = await pipeline(
  REGIONS,
  async (region) => {
    const is_cn = region === 'cn'

    const result = await agent({
      label: `dev:${region}`,
      agentType: 'sac-developer',
      prompt: `## 项目上下文
项目：${PROJECT}
区域：${region}
${is_cn ? '源类型：国内（华为云镜像、PyPI镜像）' : '源类型：海外（官方源）'}

## 架构决策
${JSON.stringify(architectResult.decisions, null, 2)}

## 变量设计
${JSON.stringify(architectResult.variables, null, 2)}

## 任务
在 practices/${PROJECT}/${region}/ 下创建文件：
1. terraform/deploying-${PROJECT}.tf
2. scripts/install_${PROJECT}.sh（4阶段模式）
3. scripts/docker-compose.yaml（如适用）
4. .extension

输出创建的文件列表及路径`,
      schema: {
        type: 'object',
        properties: {
          files_created: { type: 'array', items: { type: 'string' } },
          install_strategy: { type: 'string' },
          docker_image_source: { type: 'string' },
        },
        required: ['files_created'],
      },
    })

    return { region, ...result }
  },
)

log(`✅ 开发完成：${REGIONS.length} 个区域`)
devResults.forEach(r => log(`   ${r.region}: ${r.files_created.length} 个文件`))

// ============================================================================
// Phase 3: 测试 + 安全审查（并行）
// ============================================================================
phase('Test & Security')
log('🧪 测试 Agent + 安全审查 Agent 并行工作...')

const [testResult, securityResult] = await parallel([
  async () => {
    const result = await agent({
      label: 'tester',
      agentType: 'sac-tester',
      prompt: `## 项目上下文
项目：${PROJECT}
区域：${REGIONS.join(', ')}

请检查 practices/${PROJECT}/ 下所有文件，按 sac-tester.json 中的 validation_checklist 逐项验证。

输出验证结果。`,
      schema: {
        type: 'object',
        properties: {
          passed: { type: 'boolean' },
          issues: { type: 'array', items: { type: 'object', properties: { severity: { type: 'string', enum: ['error', 'warning', 'info'] }, file: { type: 'string' }, message: { type: 'string' } }, required: ['severity', 'file', 'message'] } },
          summary: { type: 'string' },
        },
        required: ['passed', 'issues', 'summary'],
      },
    })
    return result
  },
  async () => {
    const result = await agent({
      label: 'security',
      agentType: 'sac-security',
      prompt: `## 项目上下文
项目：${PROJECT}
区域：${REGIONS.join(', ')}

请检查 practices/${PROJECT}/ 下所有文件，按 sac-security.json 中的 check_rules（SEC-001 至 SEC-008）逐条审计。

输出审计结果。`,
      schema: {
        type: 'object',
        properties: {
          passed: { type: 'boolean' },
          findings: { type: 'array', items: { type: 'object', properties: { id: { type: 'string' }, severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] }, file: { type: 'string' }, message: { type: 'string' }, remediated: { type: 'boolean' } }, required: ['id', 'severity', 'file', 'message', 'remediated'] } },
          summary: { type: 'string' },
        },
        required: ['passed', 'findings', 'summary'],
      },
    })
    return result
  },
])

if (!testResult.passed) {
  log(`⚠️ 测试发现问题：${testResult.issues.length} 个`)
  testResult.issues.filter(i => i.severity === 'error').forEach(i => log(`   ❌ ${i.file}: ${i.message}`))
} else {
  log('✅ 测试全部通过')
}

if (!securityResult.passed) {
  log(`⚠️ 安全审查发现问题：${securityResult.findings.length} 个`)
  securityResult.findings.filter(f => f.severity === 'critical' || f.severity === 'high').forEach(f => log(`   🔴 ${f.id} [${f.severity}] ${f.file}: ${f.message}`))
} else {
  log('✅ 安全审查全部通过')
}

// ============================================================================
// Phase 4: 文档 — 技术文档 + 业务文档
// ============================================================================
phase('Document')
log('📝 文档 Agent 开始工作...')

const docResults = await pipeline(
  REGIONS,
  async (region) => {
    const is_cn = region === 'cn'

    const result = await agent({
      label: `doc:${region}`,
      agentType: 'sac-documenter',
      prompt: `## 项目上下文
项目：${PROJECT}
区域：${region}
语言：${is_cn ? '中文' : '英文'}

## 任务
在 practices/${PROJECT}/${region}/ 下创建文档：
1. docs/README.md（10个标准章节）
2. docs/Solution-Details.md（面向客户的价值描述）

输出创建的文件列表。`,
      schema: {
        type: 'object',
        properties: {
          files_created: { type: 'array', items: { type: 'string' } },
          doc_language: { type: 'string' },
        },
        required: ['files_created'],
      },
    })

    return { region, ...result }
  },
)

log(`✅ 文档完成：${REGIONS.length} 个区域`)

// ============================================================================
// Phase 5: 交付 — 打包、URL 生成、归档
// ============================================================================
phase('Deliver')
log('📦 交付 Agent 开始工作...')

const deliveryResult = await agent({
  label: 'delivery',
  agentType: 'sac-delivery',
  prompt: `## 项目上下文
项目：${PROJECT}
区域：${REGIONS.join(', ')}

## 任务
1. 创建 release/${PROJECT}/ 目录结构，从 practices/${PROJECT}/ 复制文件
2. 为每个区域生成 url.txt（TF/sh/RFS URL）
3. 打包 release/${PROJECT}/${PROJECT}.zip
4. 在 docs/version.log 追加版本记录

输出交付结果。`,
  schema: {
    type: 'object',
    properties: {
      release_dir: { type: 'string' },
      regions_released: { type: 'array', items: { type: 'string' } },
      url_files: { type: 'array', items: { type: 'string' } },
      archive_file: { type: 'string' },
      summary: { type: 'string' },
    },
    required: ['release_dir', 'regions_released', 'url_files', 'archive_file', 'summary'],
  },
})

log(`✅ 交付完成`)
log(`   目录：${deliveryResult.release_dir}`)
log(`   归档：${deliveryResult.archive_file}`)
log(`   区域：${deliveryResult.regions_released.join(', ')}`)

// ============================================================================
// 最终汇总
// ============================================================================
log('')
log('='.repeat(60))
log(`🎉 SAC ${PROJECT} 全流程交付完成！`)
log('='.repeat(60))
log('')
log(`📋 最终总结：`)
log(`   架构：${architectResult.decisions.deployment_type} 版`)
log(`   区域：${REGIONS.join(', ')}`)
log(`   模板格式：${architectResult.decisions.template_format}`)
log(`   安装策略：${architectResult.decisions.install_strategy}`)
log('')
log(`🧪 质量检查：`)
log(`   测试：${testResult.passed ? '✅ 通过' : '⚠️ ' + testResult.issues.filter(i => i.severity === 'error').length + ' 个错误'}`)
log(`   安全：${securityResult.passed ? '✅ 通过' : '⚠️ ' + securityResult.findings.filter(f => f.severity === 'critical' || f.severity === 'high').length + ' 个高危'}`)
log('')
log(`📦 交付物：`)
log(`   发布目录：${deliveryResult.release_dir}`)
log(`   归档包：${deliveryResult.archive_file}`)

return {
  project: PROJECT,
  regions: REGIONS,
  decisions: architectResult.decisions,
  test_passed: testResult.passed,
  security_passed: securityResult.passed,
  release_dir: deliveryResult.release_dir,
  archive_file: deliveryResult.archive_file,
  url_files: deliveryResult.url_files,
}

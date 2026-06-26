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
// 每个阶段都引用 .claude/agents/ 中的 Agent 定义作为上下文
// ============================================================================

const PROJECT = args.project          // e.g. "litellm"
const REGIONS = args.regions          // e.g. ["cn", "hk", "intl"]
const DESCRIPTION = args.description  // e.g. "Multi-model API Gateway"

log(`🚀 SAC 全流程启动：${PROJECT}`)
log(`   区域：${REGIONS.join(', ')}`)
log(`   描述：${DESCRIPTION}`)

// ============================================================================
// Phase 1: 架构师 — 方案设计与技术评估
// ============================================================================
phase('Architect')
log('🧠 架构师开始工作...')

const architectResult = await agent(`
你是一名 SAC 架构师 Agent（参考 .claude/agents/sac-architect.json）。

项目：${PROJECT}
区域：${REGIONS.join(', ')}
描述：${DESCRIPTION}

请完成以下工作：

## 1. 技术评估
- 分析该方案的技术可行性
- 列出技术栈和依赖清单
- 评估部署复杂度

## 2. 方案设计
- 设计架构（单机标准版 vs 高可用版）
- 列出标准资源清单（VPC/Subnet/SG/EIP/ECS）
- 设计安全组规则（ICMP/SSH/应用端口）

## 3. 决策点确认
- 模板格式：.tf (HCL) 还是 .tf.json (JSON)？
- 安装策略：内联 user_data 还是 OBS 下载？
- 语言：中文还是英文？
- 容器化：Docker Compose 还是直接安装？

## 4. 变量设计
- 列出 7 个标准变量（solution_name, ecs_flavor, ecs_password 等）
- 列出应用专属变量（db_password, master_key 等）
- 每个变量含 type/default/validation

## 输出格式
返回 JSON，包含：
- feasibility: 可行性分析
- architecture: 架构设计（含 ASCII 图）
- decisions: 决策点及选择
- variables: 变量设计表
- resources: 资源清单
- dependencies: 依赖清单
`, { schema: {
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
}})

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
    const l = is_cn ? 'zh' : 'en'

    const result = await agent(`
你是一名 SAC 开发 Agent（参考 .claude/agents/sac-developer.json）。

项目：${PROJECT}
区域：${region}
语言：${l}

## 架构决策
${JSON.stringify(architectResult.decisions, null, 2)}

## 变量设计
${JSON.stringify(architectResult.variables, null, 2)}

## 任务
在 practices/${PROJECT}/${region}/ 目录下创建以下文件：

### 1. terraform/deploying-${PROJECT}.tf
遵循以下规则：
- Provider 块只写 region
- required_providers 用对象格式
- 资源链：VPC → Subnet → SecGroup → EIP → ECS
- 安全组含 allow_ping（ICMP） + cloud_shell（22端口 121.36.59.153/32） + 应用端口
- ECS 挂载 hss + ces agent_list
- user_data 最小化：密码→下载→执行→清理
- 变量含 validation 验证
- 输出含访问地址/SSH/日志路径
${is_cn ? '- pip 用清华 PyPI 镜像\n- Docker CE 从 mirrors.huaweicloud.com' : '- Docker CE 从 download.docker.com\n- 不需要 PyPI 镜像'}

### 2. scripts/install_${PROJECT}.sh
4 阶段标准模式：
- Stage 1: 系统准备（apt update, base packages）
- Stage 2: Docker 安装（国内/海外差异处理）
- Stage 3: 应用配置（目录、compose、.env）
- Stage 4: 启动 + 健康检查循环（最长 120s）
- pip install 必须 --break-system-packages --ignore-installed

### 3. scripts/docker-compose.yaml（如适用）
- 数据目录挂载到 ./volumes/
- 数据库配 healthcheck
- 敏感信息走 .env 文件

### 4. .extension
- 参数分组配置
- 支持 zh-cn 和 en-us 国际化

输出：创建的文件列表及路径
`, { label: `dev:${region}`, schema: {
  type: 'object',
  properties: {
    files_created: { type: 'array', items: { type: 'string' } },
    install_strategy: { type: 'string' },
    docker_image_source: { type: 'string' },
  },
  required: ['files_created'],
}})

    return { region, ...result }
  }
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
    const result = await agent(`
你是一名 SAC 测试 Agent（参考 .claude/agents/sac-tester.json）。

项目：${PROJECT}
区域：${REGIONS.join(', ')}

## 验证清单

### 模板检查
1. required_providers 是对象格式？
2. Provider 只有 region？
3. 资源名用 var.solution_name 前缀？
4. user_data 最小化？
5. 无 random provider / uuid()？
6. 无硬编码凭证？

### 脚本检查
1. pip 用 --break-system-packages --ignore-installed？
2. 国内版用 PyPI 镜像？
3. 国内版 Docker 用 mirrors.huaweicloud.com？
4. 健康检查循环存在？
5. 环境变量在 .bashrc 中 export？

### 安全组检查
1. 含 allow_ping（ICMP 0.0.0.0/0）？
2. SSH 仅限 121.36.59.153/32？
3. 应用端口开放 0.0.0.0/0？

请检查 practices/${PROJECT}/ 下所有文件，输出验证结果。
`, { label: 'tester', schema: {
  type: 'object',
  properties: {
    passed: { type: 'boolean' },
    issues: { type: 'array', items: { type: 'object', properties: { severity: { type: 'string', enum: ['error', 'warning', 'info'] }, file: { type: 'string' }, message: { type: 'string' } }, required: ['severity', 'file', 'message'] } },
    summary: { type: 'string' },
  },
  required: ['passed', 'issues', 'summary'],
}})
    return result
  },
  async () => {
    const result = await agent(`
你是一名 SAC 安全审查 Agent（参考 .claude/agents/sac-security.json）。

项目：${PROJECT}
区域：${REGIONS.join(', ')}

## 安全审计清单

请检查 practices/${PROJECT}/ 下所有文件，逐条审计：

### SEC-001 [CRITICAL] 凭证泄露
- 脚本中是否有 AK/SK/API Key 硬编码？

### SEC-002 [CRITICAL] API Key 泄露
- 是否有 master_key/api_key/token 硬编码？

### SEC-003 [HIGH] 高危端口开放
- 是否有 22/3306/5432/6379/27017 开放到 0.0.0.0/0？

### SEC-004 [HIGH] SSH 访问控制
- SSH 端口是否只允许 121.36.59.153/32？

### SEC-005 [MEDIUM] SWR 镜像认证
- 是否有 docker login 命令？

### SEC-006 [MEDIUM] 数据库密码安全
- 密码是否通过环境变量传入？

### SEC-007 [LOW] 容器特权模式
- 是否有 privileged: true？

### SEC-008 [LOW] 监控配置
- ECS 是否启用 hss + ces？

输出审计结果。
`, { label: 'security', schema: {
  type: 'object',
  properties: {
    passed: { type: 'boolean' },
    findings: { type: 'array', items: { type: 'object', properties: { id: { type: 'string' }, severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] }, file: { type: 'string' }, message: { type: 'string' }, remediated: { type: 'boolean' } }, required: ['id', 'severity', 'file', 'message', 'remediated'] } },
    summary: { type: 'string' },
  },
  required: ['passed', 'findings', 'summary'],
}})
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
    const l = is_cn ? 'zh' : 'en'

    const result = await agent(`
你是一名 SAC 文档 Agent（参考 .claude/agents/sac-documenter.json）。

项目：${PROJECT}
区域：${region}
语言：${l}

## 任务
在 practices/${PROJECT}/${region}/ 下创建或更新文档：

### 1. docs/README.md
包含以下标准章节：
1. 标题 — 方案名 + 一句话描述
2. 方案概述
3. 方案架构（ASCII 图 + 资源表）
4. 适用场景（3-5 个）
5. 方案优势（4-6 个）
6. 部署指南（前置条件 + 步骤 + 参数表）
7. 开始使用（访问方式 + API 示例）
8. 预估费用（按需 + 包年包月）
9. 快速卸载
10. 更多资源

### 2. docs/Solution-Details.md
面向客户的价值描述，包含：
- 方案简介
- 核心功能
- 客户价值
- 技术优势
- 适用行业

语言：${is_cn ? '中文' : '英文'}
`, { label: `doc:${region}`, schema: {
  type: 'object',
  properties: {
    files_created: { type: 'array', items: { type: 'string' } },
    doc_language: { type: 'string' },
  },
  required: ['files_created'],
}})

    return { region, ...result }
  }
)

log(`✅ 文档完成：${REGIONS.length} 个区域`)

// ============================================================================
// Phase 5: 交付 — 打包、URL 生成、归档
// ============================================================================
phase('Deliver')
log('📦 交付 Agent 开始工作...')

const deliveryResult = await agent(`
你是一名 SAC 交付 Agent（参考 .claude/agents/sac-delivery.json）。

项目：${PROJECT}
区域：${REGIONS.join(', ')}

## 任务

### 1. 创建 release/${PROJECT}/ 目录结构
按区域创建子目录，从 practices/${PROJECT}/ 复制文件。

### 2. 生成 URL 清单
为每个区域生成 url.txt（或 url_ha.txt / url_standard.txt）：
- TF: Terraform 模板直链
- sh: Shell 脚本直链
- RFS_intl: 国际站一键部署 URL
- RFS_zh-cn: 中国站一键部署 URL

### 3. 打包
创建 release/${PROJECT}/${PROJECT}.zip。

### 4. 版本记录
在 docs/version.log 中追加当前版本记录。

请输出交付结果。
`, { label: 'delivery', schema: {
  type: 'object',
  properties: {
    release_dir: { type: 'string' },
    regions_released: { type: 'array', items: { type: 'string' } },
    url_files: { type: 'array', items: { type: 'string' } },
    archive_file: { type: 'string' },
    summary: { type: 'string' },
  },
  required: ['release_dir', 'regions_released', 'url_files', 'archive_file', 'summary'],
}})

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
log(``)
log(`📋 最终总结：`)
log(`   架构：${architectResult.decisions.deployment_type} 版`)
log(`   区域：${REGIONS.join(', ')}`)
log(`   模板格式：${architectResult.decisions.template_format}`)
log(`   安装策略：${architectResult.decisions.install_strategy}`)
log(``)
log(`🧪 质量检查：`)
log(`   测试：${testResult.passed ? '✅ 通过' : '⚠️ ' + testResult.issues.filter(i => i.severity === 'error').length + ' 个错误'}`)
log(`   安全：${securityResult.passed ? '✅ 通过' : '⚠️ ' + securityResult.findings.filter(f => f.severity === 'critical' || f.severity === 'high').length + ' 个高危'}`)
log(``)
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

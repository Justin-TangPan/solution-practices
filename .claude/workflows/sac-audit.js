export const meta = {
  name: 'sac-audit',
  description: 'SAC 审计流程：测试 + 安全审查；仅在给出 release_package 时追加只读交付包核验',
  phases: [
    { title: 'Test', detail: '模板与脚本验证' },
    { title: 'Security', detail: '安全审计' },
    { title: 'Report', detail: '审计报告汇总' },
  ],
}

const PROJECT = args.project
const REGIONS = args.regions || ['cn', 'intl']
const RELEASE_PACKAGE = args.release_package || null

log(`🔍 SAC 审计启动：${PROJECT} - ${REGIONS.join(', ')}`)

phase('Test')
const testResult = await agent({
  label: 'tester',
  agentType: 'sac-tester',
  prompt: `## 项目上下文
项目：${PROJECT}，区域：${REGIONS.join(', ')}

	检查 practices/${PROJECT}/ 下所有文件，按 skills/reference/validation-checklist.md 逐项验证。

输出结果。`,
  schema: {
    type: 'object',
    properties: {
      passed: { type: 'boolean' },
      issues: { type: 'array', items: { type: 'object', properties: {
        severity: { type: 'string', enum: ['error', 'warning', 'info'] },
        file: { type: 'string' },
        message: { type: 'string' },
      }, required: ['severity', 'file', 'message'] } },
      summary: { type: 'string' },
    },
    required: ['passed', 'issues', 'summary'],
  },
})

phase('Security')
const securityResult = await agent({
  label: 'security',
  agentType: 'sac-security',
  prompt: `## 项目上下文
项目：${PROJECT}，区域：${REGIONS.join(', ')}

	检查 practices/${PROJECT}/ 下所有文件，按 skills/reference/security-check-rules.md（SEC-001 至 SEC-008）逐条审计。

输出审计结果。`,
  schema: {
    type: 'object',
    properties: {
      passed: { type: 'boolean' },
      findings: { type: 'array', items: { type: 'object', properties: {
        id: { type: 'string' }, severity: { type: 'string' }, file: { type: 'string' },
        message: { type: 'string' }, remediated: { type: 'boolean' },
      }, required: ['id', 'severity', 'file', 'message', 'remediated'] } },
      summary: { type: 'string' },
    },
    required: ['passed', 'findings', 'summary'],
  },
})

let deliveryResult = null
if (RELEASE_PACKAGE) {
  phase('Delivery package')
  deliveryResult = await agent({
    label: 'delivery-audit',
    agentType: 'sac-delivery',
    prompt: `只读核验候选交付包 ${RELEASE_PACKAGE} 的目录、确定性归档、SHA256SUMS 和门禁证据。不得修改、重打包或发布。`,
    schema: {
      type: 'object',
      properties: {
        passed: { type: 'boolean' },
        issues: { type: 'array', items: { type: 'string' } },
        summary: { type: 'string' },
      },
      required: ['passed', 'issues', 'summary'],
    },
  })
}

phase('Report')
const errors = testResult.issues.filter(i => i.severity === 'error')
const highs = securityResult.findings.filter(f => f.severity === 'critical' || f.severity === 'high')

log(`📊 审计报告：${PROJECT}`)
log(`   测试：${testResult.passed ? '✅' : '❌'} ${errors.length} 个错误`)
log(`   安全：${securityResult.passed ? '✅' : '❌'} ${highs.length} 个高危`)
if (deliveryResult) log(`   交付包：${deliveryResult.passed ? '✅' : '❌'} ${deliveryResult.issues.length} 个问题`)
log()
if (!testResult.passed) {
  log('--- 测试问题 ---')
  testResult.issues.forEach(i => log(`   [${i.severity}] ${i.file}: ${i.message}`))
}
if (!securityResult.passed) {
  log('--- 安全问题 ---')
  securityResult.findings.forEach(f => log(`   [${f.severity}] ${f.id} ${f.file}: ${f.message}`))
}

return {
  project: PROJECT,
  test: { passed: testResult.passed, issues: testResult.issues.length },
  security: { passed: securityResult.passed, findings: securityResult.findings.length },
  delivery: deliveryResult && { passed: deliveryResult.passed, issues: deliveryResult.issues.length },
}

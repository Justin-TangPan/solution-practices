export const meta = {
  name: 'sac-audit',
  description: 'SAC 审计流程：测试 + 安全审查，验证已有 practices/ 目录的质量',
  phases: [
    { title: 'Test', detail: '模板与脚本验证' },
    { title: 'Security', detail: '安全审计' },
    { title: 'Report', detail: '审计报告汇总' },
  ],
}

const PROJECT = args.project
const REGIONS = args.regions || ['cn', 'hk']

log(`🔍 SAC 审计启动：${PROJECT} - ${REGIONS.join(', ')}`)

phase('Test')
const testResult = await agent({
  label: 'tester',
  agentType: 'sac-tester',
  prompt: `## 项目上下文
项目：${PROJECT}，区域：${REGIONS.join(', ')}

检查 practices/${PROJECT}/ 下所有文件，按 sac-tester.json 中的 validation_checklist 逐项验证。

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

检查 practices/${PROJECT}/ 下所有文件，按 sac-security.json 中的 check_rules（SEC-001 至 SEC-008）逐条审计。

输出审计结果。`,
  schema: {
    type: 'object',
    properties: {
      passed: { type: 'boolean' },
      findings: { type: 'array', items: { type: 'object', properties: {
        id: { type: 'string' }, severity: { type: 'string' }, file: { type: 'string' },
        message: { type: 'string' }, remediated: { type: 'boolean' },
      }, required: ['id', 'severity', 'file', 'message', 'remediatable'] } },
      summary: { type: 'string' },
    },
    required: ['passed', 'findings', 'summary'],
  },
})

phase('Report')
const errors = testResult.issues.filter(i => i.severity === 'error')
const highs = securityResult.findings.filter(f => f.severity === 'critical' || f.severity === 'high')

log(`📊 审计报告：${PROJECT}`)
log(`   测试：${testResult.passed ? '✅' : '❌'} ${errors.length} 个错误`)
log(`   安全：${securityResult.passed ? '✅' : '❌'} ${highs.length} 个高危`)
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
}

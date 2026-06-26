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
const testResult = await agent(`
你是一名 SAC 测试 Agent（参考 .claude/agents/sac-tester.json）。
审计项目：${PROJECT}，区域：${REGIONS.join(', ')}

检查 practices/${PROJECT}/ 下所有文件：

## 模板检查
- required_providers 是对象？
- Provider 只有 region？
- 资源命名用 var.solution_name？
- user_data 最小化？
- 无 random provider / uuid()？

## 脚本检查
- pip 用 --break-system-packages？
- 国内版用 PyPI 镜像和 mirrors.huaweicloud.com？
- 健康检查循环？

## 安全组
- allow_ping（ICMP）？
- SSH 仅 121.36.59.153/32？

输出结果。
`, { schema: {
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
}})

phase('Security')
const securityResult = await agent(`
你是一名 SAC 安全审查 Agent（参考 .claude/agents/sac-security.json）。
审计项目：${PROJECT}，区域：${REGIONS.join(', ')}

检查 practices/${PROJECT}/ 下所有文件：

- SEC-001 [CRITICAL] 凭证硬编码？
- SEC-002 [CRITICAL] API Key 硬编码？
- SEC-003 [HIGH] 高危端口暴露 0.0.0.0/0？
- SEC-004 [HIGH] SSH 限 Cloud Shell IP？
- SEC-005 [MEDIUM] docker login？
- SEC-006 [MEDIUM] 密码通过环境变量？
- SEC-007 [LOW] privileged 模式？
- SEC-008 [LOW] hss + ces 监控？

输出审计结果。
`, { schema: {
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
}})

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

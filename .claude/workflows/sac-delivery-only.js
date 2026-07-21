export const meta = {
  name: 'sac-delivery-only',
  description: 'SAC 本地交付流程：整理、归档并校验 release/ 交付包',
  phases: [
    { title: 'Prepare', detail: '整理本地交付目录' },
    { title: 'Package', detail: '生成归档与校验和' },
    { title: 'Verify', detail: '核对归档内容' },
  ],
}

const PROJECT = args.project
const TARGETS = args.regions || []
const GATES = args.gates || {}

if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(PROJECT || '')) {
  throw new Error('Delivery requires a lowercase hyphenated project id')
}
if (!TARGETS.length || TARGETS.some(target => !/^(cn|intl)\/[^/]+$/.test(target))) {
  throw new Error('Delivery requires site/region targets, for example cn/cn-north-4')
}

if (!GATES.test_passed || !GATES.security_passed || !GATES.document_passed || !GATES.cloud_test_passed) {
  throw new Error('Delivery requires passing test, security, document, and user cloud-test evidence')
}

phase('Prepare')
const prepResult = await agent({
  label: 'delivery-prep',
  agentType: 'sac-delivery',
  prompt: `将 practices/${PROJECT}/ 中已通过门禁的 ${TARGETS.join(', ')} 资产复制到 release/${PROJECT}/，保持 site/region/variant 结构。只整理本地文件。`,
  schema: {
    type: 'object',
    properties: {
      release_dir: { type: 'string' },
      regions_ready: { type: 'array', items: { type: 'string' } },
    },
    required: ['release_dir', 'regions_ready'],
  },
})

phase('Package')
const archiveResult = await agent({
  label: 'delivery-archive',
  agentType: 'sac-delivery',
  prompt: `创建 release/${PROJECT}/${PROJECT}.zip 和 SHA256SUMS；不得执行外部发布、云资源变更或 Git 操作。`,
  schema: {
    type: 'object',
    properties: {
      archive_file: { type: 'string' },
      checksum_file: { type: 'string' },
      size_bytes: { type: 'number' },
    },
    required: ['archive_file', 'checksum_file', 'size_bytes'],
  },
})

phase('Verify')
const verifyResult = await agent({
  label: 'delivery-verify',
  agentType: 'sac-delivery',
  prompt: `只读核对 ${archiveResult.archive_file} 的文件清单、SHA-256 和 practices/${PROJECT}/ 源资产一致性。`,
  schema: {
    type: 'object',
    properties: { passed: { type: 'boolean' }, summary: { type: 'string' } },
    required: ['passed', 'summary'],
  },
})

if (!verifyResult.passed) throw new Error(`Local delivery verification failed: ${verifyResult.summary}`)

return {
  project: PROJECT,
  release_dir: prepResult.release_dir,
  archive_file: archiveResult.archive_file,
  checksum_file: archiveResult.checksum_file,
}

import assert from 'node:assert/strict';
import { access, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { diagnose } from '../src/doctor.js';
import { availablePractices, executeInstall, updateInstalled } from '../src/installer.js';

async function fixture(t) {
  const dir = await mkdtemp(join(tmpdir(), 'sac-cli-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  return dir;
}

test('formal practices come from project.config.json', async () => {
  assert.deepEqual(await availablePractices(), ['litellm', 'supabase', 'openjiuwen']);
});

test('init installs Codex assets, skills, and manifest', async (t) => {
  const dir = await fixture(t);
  const result = await executeInstall({ targetDir: dir, components: ['codex', 'skills'] });
  assert.equal(result.manifest.components.codex, true);
  assert.equal(result.manifest.components.skills, true);
  assert.match(await readFile(join(dir, 'AGENTS.md'), 'utf8'), /<!-- SAC:START -->/);
  assert.match(await readFile(join(dir, '.codex/agents/architect.toml'), 'utf8'), /name = "sac_architect"/);
  assert.match(await readFile(join(dir, 'skills/sac-testing/SKILL.md'), 'utf8'), /name: sac-testing/);
  assert.match(await readFile(join(dir, '.codex/skills/sac-testing/SKILL.md'), 'utf8'), /name: sac-testing/);
  assert.match(await readFile(join(dir, '.sac/tooling/scripts/document_pipeline/__main__.py'), 'utf8'), /cli/);
  assert.match(await readFile(join(dir, '.sac/tooling/scripts/tests/runner.py'), 'utf8'), /SAC Solution Test Report/);
  const installedTemplate = await readFile(join(dir, '.sac/tooling/scripts/document_pipeline/templates/company-solution-guide.docx'));
  const sourceTemplate = await readFile(join(process.cwd(), 'scripts/document_pipeline/templates/company-solution-guide.docx'));
  assert.deepEqual(installedTemplate, sourceTemplate);
  const index = JSON.parse(await readFile(join(dir, 'skills-index.json'), 'utf8'));
  assert.ok(index.skills.some((skill) => skill.id === 'sac-testing'));
  const persisted = JSON.parse(await readFile(join(dir, '.sac/manifest.json'), 'utf8'));
  assert.equal(persisted.schemaVersion, 1);
  assert.ok(persisted.managedFiles['.codex/agents/architect.toml']);
});

test('init merges AGENTS.md idempotently and preserves user content', async (t) => {
  const dir = await fixture(t);
  await writeFile(join(dir, 'AGENTS.md'), '# User rules\n\nKeep this.\n');
  await executeInstall({ targetDir: dir, components: ['codex'] });
  await executeInstall({ targetDir: dir, components: ['codex'] });
  const content = await readFile(join(dir, 'AGENTS.md'), 'utf8');
  assert.match(content, /Keep this\./);
  assert.equal(content.match(/<!-- SAC:START -->/g)?.length, 1);
  assert.equal(content.match(/<!-- SAC:END -->/g)?.length, 1);
});

test('update protects user-modified managed files', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['codex'] });
  const agent = join(dir, '.codex/agents/architect.toml');
  await writeFile(agent, `${await readFile(agent, 'utf8')}\n# user edit\n`);
  const result = await updateInstalled({ targetDir: dir });
  assert.ok(result.actions.some((item) => item.action === 'conflict' && item.path === '.codex/agents/architect.toml'));
  assert.match(await readFile(agent, 'utf8'), /# user edit/);
  assert.match(await readFile(`${agent}.sac-new`, 'utf8'), /name = "sac_architect"/);
});

test('update removes obsolete managed skills but preserves modified ones', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['skills'] });
  const manifestPath = join(dir, '.sac/manifest.json');
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  for (const name of ['obsolete', 'modified']) {
    const path = `skills/${name}/SKILL.md`;
    const content = name === 'obsolete' ? 'old\n' : 'user edit\n';
    await mkdir(join(dir, 'skills', name), { recursive: true });
    await writeFile(join(dir, path), content);
    manifest.managedFiles[path] = {
      checksum: name === 'obsolete'
        ? '01d09d19c2139a46aebfb577780d123d7396e97201bc7ead210a2ebff8239dee'
        : 'outdated',
      component: 'skills',
      mode: 'managed',
    };
  }
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  const result = await updateInstalled({ targetDir: dir });
  await assert.rejects(access(join(dir, 'skills/obsolete/SKILL.md')));
  assert.equal(await readFile(join(dir, 'skills/modified/SKILL.md'), 'utf8'), 'user edit\n');
  assert.ok(result.actions.some((item) => item.action === 'remove-stale'));
  assert.ok(result.actions.some((item) => item.action === 'preserve-stale'));
});

test('update rejects stale managed paths outside the project', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['skills'] });
  const manifestPath = join(dir, '.sac/manifest.json');
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  manifest.managedFiles['../outside'] = { checksum: 'irrelevant', component: 'skills', mode: 'managed' };
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  await assert.rejects(updateInstalled({ targetDir: dir }), /Invalid managed path outside the project/);
});

test('doctor reports a healthy initialized project', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['codex', 'skills'] });
  const report = await diagnose(dir);
  assert.equal(report.ok, true);
  assert.deepEqual(report.results, [{ level: 'ok', code: 'healthy', message: 'SAC installation is healthy.' }]);
});

test('doctor detects a missing SAC AGENTS block', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['codex'] });
  await writeFile(join(dir, 'AGENTS.md'), '# User rules\n');
  const report = await diagnose(dir);
  assert.equal(report.ok, false);
  assert.ok(report.results.some((item) => item.code === 'agents-block-invalid'));
});

test('practice installation rejects non-formal names', async (t) => {
  const dir = await fixture(t);
  await assert.rejects(
    executeInstall({ targetDir: dir, components: [], practices: ['missing'] }),
    /Unknown or non-formal practice/,
  );
});

test('formal practice installation records and copies the selected practice', async (t) => {
  const dir = await fixture(t);
  const result = await executeInstall({ targetDir: dir, components: [], practices: ['openjiuwen'] });
  assert.deepEqual(result.manifest.components.practices, ['openjiuwen']);
  for (const template of [
    'practices/openjiuwen/cn/cn-north-4/agent-studio/terraform/deploying-openjiuwen.tf',
    'practices/openjiuwen/cn/cn-north-4/jiuwenswarm/terraform/deploying-jiuwenswarm.tf',
  ]) {
    assert.match(await readFile(join(dir, template), 'utf8'), /resource\s+"huaweicloud_compute_instance"/);
  }
});

test('Codex install preserves a pre-existing config owned by the host project', async (t) => {
  const dir = await fixture(t);
  const configDir = join(dir, '.codex');
  await mkdir(configDir, { recursive: true });
  await writeFile(join(configDir, 'config.toml'), 'model_reasoning_effort = "medium"\n');
  const result = await executeInstall({ targetDir: dir, components: ['codex'] });
  assert.equal(await readFile(join(configDir, 'config.toml'), 'utf8'), 'model_reasoning_effort = "medium"\n');
  assert.ok(result.actions.some((item) => item.action === 'preserve' && item.path === '.codex/config.toml'));
});

test('dry run does not write files', async (t) => {
  const dir = await fixture(t);
  const result = await executeInstall({ targetDir: dir, components: ['codex'], dryRun: true });
  assert.ok(result.actions.length > 0);
  await assert.rejects(readFile(join(dir, '.sac/manifest.json')), /ENOENT/);
});

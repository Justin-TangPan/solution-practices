import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

test('SAC skill routing stays minimal and valid', async () => {
  const index = JSON.parse(await readFile('skills-index.json', 'utf8'));
  const ids = new Set(index.skills.map((skill) => skill.id));

  for (const skill of index.skills.filter((item) => item.path.startsWith('skills/'))) {
    const source = await readFile(skill.path, 'utf8');
    const frontmatter = source.split('---', 3)[1];
    const keys = [...frontmatter.matchAll(/^([a-z][a-z-]*):/gm)].map((match) => match[1]);
    assert.deepEqual(keys, ['name', 'description'], `${skill.id} frontmatter`);
    assert.ok(source.split('\n').length <= 130, `${skill.id} exceeds 130 lines`);
    assert.equal('tokens' in skill || 'merge_group' in skill, false, `${skill.id} has stale budget metadata`);
    for (const dependency of skill.requires) assert.ok(ids.has(dependency), `${skill.id} requires ${dependency}`);
  }

  for (const [agent, binding] of Object.entries(index.agent_skill_bindings)) {
    assert.equal(binding.mandatory.length, 2, `${agent} must load exactly two mandatory skills`);
    assert.ok(!binding.mandatory.includes('sac-document-pipeline'), `${agent} loads the compatibility alias`);
    for (const id of [...binding.mandatory, ...binding.conditional]) assert.ok(ids.has(id), `${agent} uses ${id}`);
  }
});

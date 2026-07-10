import { join } from 'node:path';
import { readFile } from 'node:fs/promises';
import { MANIFEST_PATH, MANIFEST_SCHEMA_VERSION } from './constants.js';
import { exists, readText, sha256 } from './fs-utils.js';

function result(level, code, message) {
  return { level, code, message };
}

export async function diagnose(targetDir = process.cwd()) {
  const results = [];
  const manifestFile = join(targetDir, MANIFEST_PATH);
  if (!(await exists(manifestFile))) {
    return {
      ok: false,
      results: [result('error', 'manifest-missing', 'No .sac/manifest.json; run "sac init".')],
    };
  }

  let manifest;
  try {
    manifest = JSON.parse(await readFile(manifestFile, 'utf8'));
  } catch (error) {
    return { ok: false, results: [result('error', 'manifest-invalid', error.message)] };
  }
  if (manifest.schemaVersion !== MANIFEST_SCHEMA_VERSION) {
    results.push(result('error', 'schema-unsupported', `Manifest schema is ${manifest.schemaVersion}; expected ${MANIFEST_SCHEMA_VERSION}.`));
  }

  for (const [path, metadata] of Object.entries(manifest.managedFiles ?? {})) {
    const absolute = join(targetDir, path);
    if (!(await exists(absolute))) {
      results.push(result('error', 'managed-file-missing', path));
      continue;
    }
    if (metadata.mode === 'merge-block') continue;
    const checksum = sha256(await readText(absolute));
    if (checksum !== metadata.checksum) {
      results.push(result('warning', 'managed-file-modified', path));
    }
  }

  if (manifest.components?.codex) {
    for (const required of ['AGENTS.md', '.codex/agents/architect.toml', '.codex/workflows/full-pipeline.md']) {
      if (!(await exists(join(targetDir, required)))) {
        results.push(result('error', 'codex-incomplete', required));
      }
    }
  }
  if (manifest.components?.skills) {
    for (const required of ['skills/sac-project-rules/SKILL.md', '.codex/skills/sac-project-rules/SKILL.md']) {
      if (!(await exists(join(targetDir, required)))) results.push(result('error', 'skills-incomplete', required));
    }
  }

  if (!results.length) results.push(result('ok', 'healthy', 'SAC installation is healthy.'));
  return { ok: !results.some((item) => item.level === 'error'), results, manifest };
}

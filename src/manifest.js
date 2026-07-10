import { dirname, join } from 'node:path';
import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import { MANIFEST_PATH, MANIFEST_SCHEMA_VERSION } from './constants.js';
import { exists } from './fs-utils.js';
import { migrateManifest } from './migrations/index.js';

export function emptyManifest(packageVersion, contentVersion) {
  const now = new Date().toISOString();
  return {
    schemaVersion: MANIFEST_SCHEMA_VERSION,
    packageName: 'solution-practices',
    packageVersion,
    contentVersion,
    installedAt: now,
    updatedAt: now,
    components: { codex: false, skills: false, practices: [] },
    managedFiles: {},
  };
}

export async function loadManifest(targetDir, packageVersion, contentVersion) {
  const path = join(targetDir, MANIFEST_PATH);
  if (!(await exists(path))) return emptyManifest(packageVersion, contentVersion);
  const parsed = JSON.parse(await readFile(path, 'utf8'));
  return migrateManifest(parsed);
}

export async function saveManifest(targetDir, manifest, { dryRun = false } = {}) {
  if (dryRun) return;
  const path = join(targetDir, MANIFEST_PATH);
  const temp = `${path}.tmp`;
  await mkdir(dirname(path), { recursive: true });
  await writeFile(temp, `${JSON.stringify(manifest, null, 2)}\n`);
  await rename(temp, path);
}

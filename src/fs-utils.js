import { createHash } from 'node:crypto';
import { mkdir, readFile, stat, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';

export async function exists(path) {
  try {
    await stat(path);
    return true;
  } catch (error) {
    if (error.code === 'ENOENT') return false;
    throw error;
  }
}

export function sha256(content) {
  return createHash('sha256').update(content).digest('hex');
}

export async function readText(path) {
  return readFile(path, 'utf8');
}

export async function writeText(path, content, { dryRun = false } = {}) {
  if (dryRun) return;
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, content);
}

export function toPosix(path) {
  return path.replaceAll('\\', '/');
}

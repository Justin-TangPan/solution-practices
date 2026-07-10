import { MANIFEST_SCHEMA_VERSION } from '../constants.js';

export function migrateManifest(input) {
  if (!Number.isInteger(input.schemaVersion)) {
    throw new Error('Invalid .sac/manifest.json: schemaVersion is required');
  }
  if (input.schemaVersion > MANIFEST_SCHEMA_VERSION) {
    throw new Error(
      `Manifest schema ${input.schemaVersion} is newer than this CLI supports (${MANIFEST_SCHEMA_VERSION})`,
    );
  }

  let manifest = structuredClone(input);
  // Future migrations are applied here in order, for example:
  // if (manifest.schemaVersion === 1) manifest = migrateV1ToV2(manifest);
  if (manifest.schemaVersion !== MANIFEST_SCHEMA_VERSION) {
    throw new Error(`No migration path for manifest schema ${manifest.schemaVersion}`);
  }
  manifest.components ??= { codex: false, skills: false, practices: [] };
  manifest.components.practices ??= [];
  manifest.managedFiles ??= {};
  return manifest;
}

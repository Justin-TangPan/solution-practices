#!/usr/bin/env node

import { run } from '../src/cli.js';

run(process.argv.slice(2)).catch((error) => {
  console.error(`sac: ${error.message}`);
  if (process.env.SAC_DEBUG) console.error(error.stack);
  process.exitCode = 1;
});

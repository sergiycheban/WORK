import test from 'node:test';
import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';

const trackerDir = fileURLToPath(new URL('../', import.meta.url));

test('Windows PowerShell can parse and run the update preflight', async () => {
  const run = promisify(execFile);
  const result = await run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'update-jobs.ps1', '-Profile', 'rosina', '-CheckOnly'], { cwd: trackerDir });
  assert.match(result.stdout, /Preflight passed.*profile=rosina/s);
});

test('PowerShell rejects unsafe profile IDs', async () => {
  const run = promisify(execFile);
  await assert.rejects(run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'update-jobs.ps1', '-Profile', '../escape', '-CheckOnly'], { cwd: trackerDir }), /lowercase ASCII slug/);
});

import test from 'node:test';
import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

test('Windows PowerShell can parse and run the update preflight', async () => {
  const run = promisify(execFile);
  const result = await run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'job-tracker/update-jobs.ps1', '-CheckOnly'], { cwd: process.cwd() });
  assert.match(result.stdout, /Preflight passed/);
});

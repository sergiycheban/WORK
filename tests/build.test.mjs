import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { buildHtml } from '../scripts/build-tracker.mjs';

const jobs = JSON.parse(await readFile(new URL('../data/jobs.json', import.meta.url), 'utf8'));

test('generator creates a Russian self-contained tracker containing every stable id', () => {
  const html = buildHtml(jobs);
  assert.match(html, /<!doctype html>/i);
  assert.match(html, /Трекер вакансий/);
  assert.match(html, /Подалась/);
  assert.match(html, /Архив/);
  assert.match(html, /localStorage/);
  assert.match(html, /rosina-job-applied:/);
  assert.doesNotMatch(html, /<script[^>]+src=/i);
  assert.doesNotMatch(html, /<link[^>]+rel=["']stylesheet/i);
  for (const job of jobs) assert.match(html, new RegExp(`data-job-id=["']${job.id}["']`));
});

test('command writes index.html inside job-tracker', async () => {
  const run = promisify(execFile);
  await run(process.execPath, ['job-tracker/scripts/build-tracker.mjs'], { cwd: process.cwd() });
  const html = await readFile('job-tracker/index.html', 'utf8');
  assert.match(html, /Трекер вакансий/);
});

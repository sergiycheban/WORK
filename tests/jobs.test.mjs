import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const jobsPath = new URL('../data/jobs.json', import.meta.url);

test('dataset contains valid, unique Russian vacancy records', async () => {
  const jobs = JSON.parse(await readFile(jobsPath, 'utf8'));
  assert.ok(jobs.length >= 10);
  const ids = new Set();
  for (const job of jobs) {
    for (const key of ['id', 'company', 'role', 'priority', 'status', 'summary', 'applicationUrl']) {
      assert.ok(job[key], `${key} is required`);
    }
    assert.match(job.id, /^[a-z0-9-]+$/);
    assert.ok(!ids.has(job.id), `duplicate id: ${job.id}`);
    ids.add(job.id);
    assert.ok(['Высокий', 'Средний', 'Низкий'].includes(job.priority));
    assert.ok(['active', 'archived'].includes(job.status));
    assert.ok(job.interviewProbability >= 0 && job.interviewProbability <= 1);
    assert.ok(job.offerProbability >= 0 && job.offerProbability <= job.interviewProbability);
    assert.match(`${job.summary} ${job.matches} ${job.risks}`, /[А-Яа-яЁё]/);
    assert.match(job.applicationUrl, /^https:\/\//);
  }
});


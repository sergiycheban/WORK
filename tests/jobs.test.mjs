import test from 'node:test';
import assert from 'node:assert/strict';
import { readdir, readFile } from 'node:fs/promises';

const root = new URL('../profiles/', import.meta.url);

async function loadProfiles() {
  const ids = await readdir(root);
  return Promise.all(ids.map(async id => ({
    id,
    profile: JSON.parse(await readFile(new URL(`${id}/profile.json`, root), 'utf8')),
    criteria: JSON.parse(await readFile(new URL(`${id}/criteria.json`, root), 'utf8')),
    jobs: JSON.parse(await readFile(new URL(`${id}/jobs.json`, root), 'utf8')),
  })));
}

test('public profile tree contains valid metadata, criteria, and jobs', async () => {
  const profiles = await loadProfiles();
  assert.ok(profiles.length >= 1);
  for (const item of profiles) {
    assert.match(item.id, /^[a-z0-9-]+$/);
    assert.equal(item.profile.id, item.id);
    assert.ok(item.profile.displayName);
    for (const key of ['locations', 'workModels', 'roles', 'seniority', 'employmentTypes']) {
      assert.ok(Array.isArray(item.criteria[key]) && item.criteria[key].length, `${item.id}: ${key}`);
    }
    const ids = new Set();
    for (const job of item.jobs) {
      for (const key of ['id', 'company', 'role', 'priority', 'status', 'summary', 'applicationUrl']) assert.ok(job[key], `${item.id}: ${key}`);
      assert.match(job.id, /^[a-z0-9-]+$/);
      assert.ok(!ids.has(job.id), `${item.id}: duplicate ${job.id}`);
      ids.add(job.id);
      assert.ok(['Высокий', 'Средний', 'Низкий'].includes(job.priority));
      assert.ok(['active', 'archived'].includes(job.status));
      assert.ok(job.interviewProbability >= 0 && job.interviewProbability <= 1);
      assert.ok(job.offerProbability >= 0 && job.offerProbability <= job.interviewProbability);
      assert.match(`${job.summary} ${job.matches} ${job.risks}`, /[А-Яа-яЁё]/);
    }
  }
});

test('private CV tree is ignored by Git rules', async () => {
  const ignore = await readFile(new URL('../.gitignore', import.meta.url), 'utf8');
  assert.match(ignore, /^private-cv\/$/m);
});

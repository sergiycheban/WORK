import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';
import { buildHtml, loadPublicProfiles } from '../scripts/build-tracker.mjs';

const profiles = await loadPublicProfiles(new URL('../profiles/', import.meta.url));
const trackerDir = fileURLToPath(new URL('../', import.meta.url));

test('generator embeds every profile and job in one Russian site', () => {
  const html = buildHtml(profiles);
  assert.match(html, /Выберите кандидата/);
  assert.match(html, /profileSelect/);
  assert.match(html, /Rosina Glavanar/);
  assert.doesNotMatch(html, /private-cv|CV_Rosina|glavanarr@gmail/i);
  for (const item of profiles) for (const job of item.jobs) assert.match(html, new RegExp(`data-profile-id=["']${item.profile.id}["'][^>]*data-job-id=["']${job.id}["']`));
});

test('browser state is isolated by profile and migrates legacy Rosina keys', () => {
  const html = buildHtml(profiles);
  assert.match(html, /job-tracker:'\+profileId\+':applied:/);
  assert.match(html, /job-tracker:last-profile/);
  assert.match(html, /rosina-job-applied:/);
  assert.match(html, /migrateLegacyRosina/);
});

test('cards show decision data and explicit missing values', () => {
  const html = buildHtml(profiles);
  for (const label of ['Зарплата', 'Не указана', 'Опубликована', 'Проверена', 'Уровень', 'Оформление', 'Источник', 'Заметки']) assert.match(html, new RegExp(label));
});

test('command writes index.html inside job-tracker', async () => {
  const run = promisify(execFile);
  await run(process.execPath, ['scripts/build-tracker.mjs'], { cwd: trackerDir });
  const html = await readFile(new URL('../index.html', import.meta.url), 'utf8');
  assert.match(html, /Выберите кандидата/);
});

import test from 'node:test';
import assert from 'node:assert/strict';
import { validateProfileId, criteriaComplete, makeCriteriaFromAnswers } from '../scripts/profile-tools.mjs';

test('profile IDs accept stable slugs and reject paths or uppercase text', () => {
  assert.equal(validateProfileId('ivan-petrov'), 'ivan-petrov');
  for (const bad of ['', '../ivan', 'Ivan', 'иван', 'ivan petrov']) assert.throws(() => validateProfileId(bad));
});

test('criteria completeness requires all search-driving arrays', () => {
  assert.equal(criteriaComplete({ locations:['Remote EU'], workModels:['Remote'], roles:['UX Designer'], seniority:['Middle'], employmentTypes:['Full-time'] }), true);
  assert.equal(criteriaComplete({ locations:[], workModels:['Remote'], roles:['UX Designer'], seniority:['Middle'], employmentTypes:['Full-time'] }), false);
});

test('wizard answers produce normalized criteria', () => {
  const criteria = makeCriteriaFromAnswers({ locations:'Remote EU, Bulgaria', workModels:'Remote', roles:'UX Designer, Product Designer', seniority:'Middle, Senior', employmentTypes:'Full-time, B2B', salary:'1500', exclusions:'Gambling, Adult' });
  assert.deepEqual(criteria.locations, ['Remote EU', 'Bulgaria']);
  assert.equal(criteria.salary.preferredNetEurMonthly, 1500);
  assert.deepEqual(criteria.excludedIndustries, ['Gambling', 'Adult']);
});

const split = value => String(value ?? '').split(',').map(item => item.trim()).filter(Boolean);

export function validateProfileId(id) {
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(String(id ?? ''))) throw new Error('Profile must be a lowercase ASCII slug, for example: ivan-petrov');
  return id;
}

export function criteriaComplete(criteria) {
  return ['locations', 'workModels', 'roles', 'seniority', 'employmentTypes'].every(key => Array.isArray(criteria?.[key]) && criteria[key].length > 0);
}

export function makeCriteriaFromAnswers(answers) {
  const salaryValue = Number(answers.salary);
  return {
    locations: split(answers.locations),
    workModels: split(answers.workModels),
    roles: split(answers.roles),
    seniority: split(answers.seniority),
    employmentTypes: split(answers.employmentTypes),
    salary: { preferredNetEurMonthly: Number.isFinite(salaryValue) && salaryValue > 0 ? salaryValue : null, acceptableNetEurMonthly: null, maximum: null },
    languages: split(answers.languages),
    workAuthorization: answers.workAuthorization?.trim() || 'Не указано',
    relocation: /^y|yes|да$/i.test(answers.relocation?.trim() || ''),
    excludedIndustries: split(answers.exclusions),
  };
}

# Создание публичного профиля из приватного CV

Используй значения `PROFILE_ID`, `CV_PATH` и `PROFILE_DIR`, добавленные в конце prompt.

Прочитай CV и создай:

- `<PROFILE_DIR>/profile.json` с полями `id`, `displayName`, `headline`, `createdDate`, `updatedDate`;
- `<PROFILE_DIR>/criteria.json` с массивами `locations`, `workModels`, `roles`, `seniority`, `employmentTypes`, а также `salary`, `languages`, `workAuthorization`, `relocation`, `excludedIndustries`;
- `<PROFILE_DIR>/jobs.json` как `[]`, если файла ещё нет.

Создай разумные рекомендуемые критерии из CV. Если CV не содержит географию, используй широкий `Remote` без выдумывания гражданства или разрешения на работу. Не копируй в публичные файлы телефон, email, точный адрес, фотографию или полный текст CV. Все пояснения пиши по-русски. Изменяй только выбранный `PROFILE_DIR`.

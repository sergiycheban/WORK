# Обновление трекера вакансий Росины Главанар

Это утверждённая повторяемая операция обслуживания. Не задавай уточняющих вопросов и не меняй архитектуру проекта.

Рабочие файлы:

- CV: `CV_Rosina-Glavanar.pdf`
- критерии: `docs/superpowers/specs/2026-07-03-job-search-design.md`
- данные: `job-tracker/data/jobs.json`
- генератор: `job-tracker/scripts/build-tracker.mjs`
- тесты: `job-tracker/tests/*.test.mjs`

Выполни полный поиск актуальных вакансий на текущую дату:

- remote по Европе;
- remote по Болгарии;
- remote, hybrid или office только в Пловдиве;
- Product Designer, UI/UX Designer, UI Designer, UX Designer, Web Designer, Design Systems Designer и близкие роли уровня Middle/Senior;
- full-time штат предпочтителен; долгосрочный full-time B2B/contract допустим;
- без релокации и без отраслевых исключений.

Правила:

1. Используй интернет-поиск и по возможности прямые карьерные страницы работодателей.
2. Проверь каждую текущую активную запись. Закрытые или недоступные вакансии не удаляй: поставь `status: "archived"`.
3. Добавляй только реально активные вакансии с рабочей HTTPS-ссылкой и допустимой географией.
4. Не добавляй дубли. ID формируй стабильно из компании и роли: lowercase ASCII slug с дефисами. Существующие ID не меняй.
5. Все описательные поля (`summary`, `matches`, `risks`, `tailoring`, `notes`) пиши по-русски.
6. Сравнивай требования с CV, а не только с названием роли.
7. `interviewProbability` и `offerProbability` должны быть числами от 0 до 1; вероятность оффера не выше вероятности интервью. Оценивай консервативно.
8. Приоритеты: `Высокий`, `Средний`, `Низкий`. Статусы: `active`, `archived`.
9. Обнови `verifiedDate` для проверенных записей. Не записывай cookies, токены или данные браузерного профиля.
10. После изменения запусти:

```powershell
node --test job-tracker/tests/*.test.mjs
node job-tracker/scripts/build-tracker.mjs
```

Заверши только если тесты проходят и `job-tracker/index.html` пересобран.


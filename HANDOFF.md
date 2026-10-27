# Quesly App: передача в новий чат (22.10.2026)

Відкрий новий чат Claude Code у папці `C:\Users\user\Desktop\Quesly-App` і почни з: «Прочитай HANDOFF.md, CLAUDE.md і docs/QUESLY_BRIEF.md».

## Де що
- Код: `C:\Users\user\Desktop\Quesly-App` (Xcode: застосунок `Quesly`, віджет `QueslyWidget`, спільне `Shared`).
- GitHub: ViktorPaskar/Quesly-App, гілка `claude/eloquent-faraday-pqg0gs`.
- Бриф продукту: `docs/QUESLY_BRIEF.md`. Правила роботи: `CLAUDE.md`.
- Архів-копія всієї папки (з історією git): `C:\Users\user\Desktop\Quesly-App-backup-2026-10-22.zip`.

## Незавершене
- Коміт `5e1e939` «New Quesly logo» є тільки локально, не відправлений.
  Після 1 листопада 2026 (коли відновляться хвилини GitHub Actions): `git push`, зібрати в Xcode, перевірити вигляд логотипа.
- До 1 листопада не пушити в Quesly-App без явного прохання: macOS CI хвилини закінчились.

## Спільне з сайтом (quesly.me, окремий репозиторій ViktorPaskar/Q)
- Питання застосунку дзеркаляться на сайті в `QUESTIONS` у `quesly-site/assets/js/main.js` (копія QuestionBank). Змінюєш банк питань у застосунку — повідом, щоб оновити сайт.
- Бейджі (10 шестикутників, SVG) лежать і на сайті: `quesly-site/assets/img/badges/b1..b10.svg`; оригінали на Робочому столі `1.svg`…`10.svg`.
- Рішення бренду: маскот Quby прибраний назавжди; аватари — «стікер» (біле обрамлення, лаймове кільце = відповів сьогодні); реакції ❤️ 💚 🥰 🥹 👍 SAME; кольори #07583D (зелений), #D4FF00 (лайм); шрифт Outfit.

## Мова і стиль
- Спілкування українською, просто, без технічних деталей.
- Економити кредити: правки пачкою, grep замість перечитування файлів.

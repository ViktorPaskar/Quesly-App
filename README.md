# Quesly — iOS

**One question a day. Millions of stories.**

Нативное iOS-приложение на SwiftUI (iOS 17+), собранное по Figma-макетам, Core User Journey и демо-прототипу.

## Как запустить

1. Нужен Mac с **Xcode 16** или новее.
2. Откройте `Quesly.xcodeproj`.
3. Выберите симулятор iPhone (например, iPhone 16) и нажмите **Run** (⌘R).
4. Чтобы запустить на своём iPhone: *Target Quesly → Signing & Capabilities → Team* — выберите свой Apple ID. При необходимости поменяйте Bundle ID (`app.quesly.ios`).

## Что реализовано (Core User Journey)

| Экран | Что делает |
|---|---|
| Splash | Анимированный зелёно-лаймовый градиент с логотипом |
| Welcome | Онбординг, «Get started» / «I already have an account» |
| Sign Up / Sign In | Валидация полей, показ пароля, согласие с условиями |
| Daily Question | Вопрос дня на весь экран с лаймовыми акцентами → «Answer» |
| Answer | Карточка ответа, лимит 200 символов с кольцом прогресса, таймер до следующего вопроса → «Submit» → лаймовая вспышка |
| Dual Feed | Вкладки World / Friends, баннер «Today's Question» с обратным отсчётом, pull-to-refresh |
| Reactions | Только позитивные: ❤️ 🔥 🙂 👏, тактильный отклик, анимация |
| Share | Экспорт ответа в карточку для сторис 9:16 (Instagram / TikTok) + сохранение в Фото |
| Archive | Your Answers / Saved Answers (закладки) |
| Notifications | Реакции, подписки, новые бейджи, «Your new Answer was posted!» |
| Profile | Шапка с паттерном, статистика (ответы, подписки, подписчики, серия), история ответов |
| Чужой профиль | Follow / Followed |
| Edit Profile | Никнейм, email, телефон, город, пароль, «About» |
| Following / Followers | Поиск, подписка/отписка |
| Profile menu | Achievements, Invite Friends, Settings, Feedback |
| Achievements | Гексагональные бейджи, прогресс считается из реальных данных (серия, кол-во ответов и т.д.) |
| Settings | Ежедневное напоминание (локальные уведомления) с выбором времени, приватный аккаунт, выход, удаление аккаунта |
| Feedback | Звёзды, теги, текст |

Состояние (вход, ответы, закладки, реакции, подписки, профиль) сохраняется между запусками. Новый вопрос появляется каждый день в полночь.

## Структура

```
Quesly/
  App/          QueslyApp (корневой флоу), MainTabView (таббар + навигация)
  Core/         Theme (цвета/шрифты), Models, AppStore (состояние), MockData, NotificationScheduler
  Components/   Logo, Avatar, HexBadge, AnswerCard, кнопки, табы
  Features/     Onboarding, Question, Feed, Archive, Notifications, Profile, Share
```

## Что нужно доделать до App Store

- **Бэкенд.** Сейчас данные — моки в `Core/MockData.swift`, вся логика собрана в `Core/AppStore.swift`: методы `signUp`, `submitAnswer`, `toggleReaction`, `toggleFollow` и т.д. нужно заменить вызовами API (Firebase / Supabase / свой сервер). AI-генерация вопроса дня — тоже на стороне сервера.
- **Ассеты из Figma.** Логотип-вордмарк сейчас набран системным шрифтом: экспортируйте SVG из Figma в `Assets.xcassets` и подставьте в `Components/QueslyLogo.swift`. Фирменный шрифт подключается в одном месте — `Font.quesly` в `Core/Theme.swift`. Аватары генерируются из инициалов, пока нет загрузки фото.
- **Push-уведомления** с сервера (сейчас только локальное ежедневное напоминание).
- **Модерация** ответов: кнопка Report уже есть в меню «…».

---
name: apple-hig
description: Apple Human Interface Guidelines compliance for Quesly. Use when checking or choosing native iOS patterns — navigation, tab bars, sheets, menus, controls, typography, Dynamic Type, SF Symbols, safe areas, touch targets, haptics, dark mode, accessibility (VoiceOver, Reduce Motion, contrast) — and before App Store submission.
---

# Apple HIG — Quesly compliance guide

Apply the HIG pragmatically: native behaviour by default, brand expression only where it adds meaning.

## Layout & safe areas

- Content never under the status bar/Dynamic Island or home indicator unless it is a full-bleed background (`Color.qGreen.ignoresSafeArea()` is fine; text and buttons are not).
- Horizontal screen margin = `DS.Space.screen` (20 pt). Readable width: long text should not exceed ~600 pt on large devices.
- Spacing on the 4-pt grid (`DS.Space`). Related items closer than unrelated ones (proximity).
- Keyboard: inputs scroll into view; `.scrollDismissesKeyboard(.interactively)` on forms; primary CTA stays reachable.

## Touch & controls

- Minimum hit target **44 × 44 pt** (`DS.hitTarget`), even when the glyph is smaller (pad with `contentShape`).
- One primary (filled) button per screen; secondary = tinted/outlined/plain.
- Destructive actions: `role: .destructive` + confirmation (`confirmationDialog`) when irreversible (delete answer, delete account, block).
- Use system `Menu` for overflow (…), `.sheet` with `presentationDetents` for contextual tasks, `fullScreenCover` only for immersive flows (the daily question).
- Swipe-back must keep working: custom back headers use `dismiss()` and don't block the interactive pop gesture.

## Navigation

- Tab bar: ≤ 5 items, icons outline when idle / filled when selected, re-tap on the active tab pops to root (and should scroll to top). Badges for unread counts only.
- Hierarchy via `NavigationStack`; titles short (1–2 words). Don't nest more than 3 levels for settings-like content — prefer one grouped `Form`.

## Typography

- UI text: SF Pro via `Font.ui(size)` which maps to text styles (caption 12, footnote 13, subheadline 15, callout 16, body 17, title3 20, title2 22, title 28, largeTitle 34) → Dynamic Type works automatically.
- Brand display: Outfit via `Font.display` (scales relative to the matching text style). Use for the question, hero titles, story card only.
- Minimum 12 pt for any visible text; body text 17 pt; avoid more than 3 sizes per screen.
- Test at **Accessibility XL** sizes: no clipped text, rows grow vertically, single-line labels may truncate with `…` only if non-essential.

## Color & dark mode

- Semantic colors only (`Color.qInk`, `.qGray`, `.qBackground`, `.qSurface`, `.qField`, `.qLine`, `.qMint`, `.qBrandText`) — they have light and dark values.
- Contrast: text ≥ 4.5:1 (≥ 3:1 for ≥ 18 pt bold). Lime `#D4FF00` on white fails → only on green. White on `#07583D` passes.
- Never convey state by color alone (e.g. selected tab also changes icon fill/weight).

## SF Symbols

- All icons through `QIcon` / `Icon`. Weight matches adjacent text (regular), semibold for chevrons/close.
- Outline = idle, `.fill` = selected/active. Use symbol effects (`.bounce`) for state changes, not decoration.

## Motion & haptics

- Respect `accessibilityReduceMotion`: no looping/decorative motion, replace movement with fades.
- Durations 0.2–0.45 s; springs (`.qSpring`, `.qSmooth`). Nothing should animate for > 1 s except progress.
- Haptics: `.selection` for selection changes, `.success` for completion, `.impact(.light/.medium)` for direct manipulation. Never on scroll.

## Accessibility

- Every icon-only button: `accessibilityLabel`. Grouped rows: `accessibilityElement(children: .combine/.ignore)` + meaningful label.
- Custom toggles/selectors: `.accessibilityAddTraits(.isSelected)`.
- Decorative images `accessibilityHidden(true)`.
- Long-press-only features need an alternative (`accessibilityAction(named:)`) — e.g. the reaction tray.

## App Store readiness (check before release)

Privacy strings present for every permission used (Photos add-only, Notifications), account deletion in-app (exists in Settings), report/block for UGC (exists), no placeholder content in screenshots, launch screen matches brand green.

## Audit output

For each screen: ✅ compliant / ⚠️ minor / ❌ violation, with the rule, the evidence (screenshot area), and the fix. Count violations; the goal is **0 ❌ before release**.

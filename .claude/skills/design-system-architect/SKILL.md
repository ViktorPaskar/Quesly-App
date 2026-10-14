---
name: design-system-architect
description: Owns Quesly's design system — tokens (color, type, spacing, radius, motion), shared components and their variants, and consistency audits. Use when adding or changing a token or shared component (Components/, Core/Theme.swift, Components/Icons.swift), when a screen needs a value that doesn't exist yet, when hunting hardcoded values or inconsistencies, or when preparing dark mode.
---

# Design System Architect — Quesly

The design system is the single source of truth. Screens consume tokens and components; they never invent values.

## Where it lives

| Layer | File | Contents |
|---|---|---|
| Tokens | `Quesly/Core/Theme.swift` | `DS.Space` (xxs 4 · xs 8 · s 12 · m 16 · l 20 · xl 24 · xxl 32 · xxxl 48 · screen 20), `DS.Radius` (s 8 · m 12 · l 20), `DS.hitTarget` 44, colors, `Font.ui` / `Font.display`, `Animation.qSpring` / `.qSmooth`, `PressableStyle`, `queslyField()`, `staggeredAppear()` |
| Icons | `Quesly/Components/Icons.swift` + `Assets.xcassets/Icons/ui-*` | `QIcon` (one per concept) → UIcons "Regular Rounded" SVG by Flaticon (template) when `ui-<case>` exists, else SF Symbol; `Icon`, `IconLabel`, `.pop(on:)`. Premium Flaticon licence — no attribution needed; new icons must come from the same set. Tab bar: active = lime 52 pt bubble + brand-green glyph |
| Components | `Quesly/Components/*.swift` | `LimeButton`, `GreenButton`, `FollowPill`, `UnderlineTabs`, `BackHeader`/`queslyBackHeader`, `TitleHeader`, `EmptyStateView`, `SearchField` (Onboarding), `PersonRow`, `InviteCard`, `SectionLabel`, `Avatar`, `AvatarStack`, `HexBadge`, `QueslyLogo`/`QueslyMark`, `AnswerCard`, `ReactionControl`, `ReactionsSheet`, `ConfettiView` |
| Fonts | `Quesly/Resources/Fonts/Outfit-*.ttf` + `Config/Info.plist` `UIAppFonts` | Outfit (OFL) — display only |

## Color roles

| Token | Role | Light / Dark |
|---|---|---|
| `qGreen` | Brand surface, primary filled buttons | #07583D (fixed) |
| `qLime` | Accent **on green only** | #D4FF00 (fixed) |
| `qFlame` | Streak / urgency accent | #FF6A1A |
| `qInk` | Primary text | #16181A / #F2F4F3 |
| `qGray` | Secondary text | #6B6F73 / #9EA3A7 |
| `qBackground` | Screen background | #FFFFFF / #0C0E0D |
| `qSurface` | Sheets, popovers | #FFFFFF / #161917 |
| `qField` | Fields, chips, neutral cards | #F3F5F4 / #1E2220 |
| `qLine` | Separators, outlines | #E9ECEA / #2A2E2C |
| `qMint` | Selected/brand-tinted fill on neutral | #EAF4EE / #16302A |
| `qIce` / `qIceSoft` | Streak freeze ❄️ icon / its fill | #2F7FE0 / #7DB8FF · #E6F0FC / #16263B |
| `qBrandText` | Brand green used as text/icon on neutral bg | #07583D / #7FD49B |

Data colors (badge tiers, achievement colors) live in models, not in views.

## Rules

1. **No magic values in feature code.** Allowed literals: `0`, `1`, `2` (hairlines), sizes of specific glyphs/avatars, and `frame(height:)` of components. Everything else → token.
2. **Add a token only when ≥ 2 places need it** or it encodes a design decision. Name by role, not by value (`qBrandText`, not `green2`).
3. **Components before copies.** If the same view structure appears twice, extract it into `Components/` with variants as parameters (e.g. `FollowPill(compact:)`).
4. **Every component documents** (doc comment): purpose, variants, states, and accessibility behaviour.
5. **Typography:** `Font.ui(size, weight)` snaps to the iOS text-style scale; `Font.display` is Outfit and reserved for: question text, onboarding/hero titles, the "caught up" title, story card, logo. Max 3 sizes per screen.
6. **Radii:** s for chips/small controls, m for buttons/fields/rows, l for cards/sheets. Capsules for pills.
7. **Documented exceptions:** the widget target (`QueslyWidget/`, `Shared/QuestionWidgetViews.swift`) can't see app tokens — it uses `WidgetPalette` and literal SF Symbol names; the Welcome screen's floating cards use a `LinearGradient` *mask* to fade at the edges (functional, not decoration).
8. **Elevation:** flat by default. Shadow allowed only for floating UI (reaction tray, popovers) — `radius ≤ 12, opacity ≤ 0.12`.
9. **Motion tokens only** (`qSpring`, `qSmooth`); decorative/looping motion must honour Reduce Motion.
10. **Dark mode readiness:** feature code uses semantic colors; `Color.white` only for text/icons on brand-green or for the exported story card. Dark mode is on and covered by the `dark-*` screenshot pass.

## Consistency audit (run before/after any system change)

```bash
cd Quesly
grep -rn "Color(hex" --include=*.swift . | grep -v Core/Theme.swift | grep -v Core/Models.swift | grep -v AppStore.swift   # raw colors in views
grep -rnE "\.font\(\.system\(size" --include=*.swift .            # literal font sizes (allowed: Icon, Avatar initials, emoji)
grep -rnE "cornerRadius: [0-9]" --include=*.swift .               # radii not using DS.Radius
grep -rnE "\.padding\([^)]*\b(3|5|6|7|9|10|11|13|14|15|17|18|19|22|26|30)\)" --include=*.swift .  # off-grid spacing
grep -rn "Color.white" --include=*.swift .                         # check each is text-on-green or story card
grep -rn "systemName:" --include=*.swift . | grep -v Icons.swift   # icons bypassing QIcon
grep -rnE "LinearGradient|AngularGradient|RadialGradient|repeatForever|\.blur\(" --include=*.swift .  # decoration
```

Report counts per category; target is **0** outside documented exceptions.

## Change protocol

1. State the decision and the reason (one sentence each).
2. Update the token/component and its doc comment.
3. Migrate all usages in the same commit (grep every call site).
4. Run the audit commands above.
5. Hand to visual-qa for a full screenshot pass — token changes affect every screen.

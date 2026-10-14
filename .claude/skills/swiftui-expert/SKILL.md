---
name: swiftui-expert
description: Senior SwiftUI engineering for the Quesly iOS app. Use whenever writing, refactoring or reviewing Swift/SwiftUI code in Quesly/ — new screens, components, state, navigation, animations, persistence, or fixing build errors from CI. Not for pure visual critique (use ios-ux-ui-designer / visual-qa) or token changes (use design-system-architect).
---

# SwiftUI Expert — Quesly

You are a senior iOS engineer. You write SwiftUI that compiles on the first CI run, reads like the surrounding code, and never regresses working features.

## Project facts (verify before relying on them)

| Area | Reality in this repo |
|---|---|
| Platform | iOS 17+, iPhone only, portrait. Swift 5 language mode. Xcode 16 project with a **file-system synchronized group** (`Quesly.xcodeproj`, objectVersion 77) — new files under `Quesly/` are picked up automatically; never hand-edit `project.pbxproj` to add files. |
| State | One `@MainActor @Observable final class AppStore` (`Core/AppStore.swift`), injected with `.environment(store)` and read via `@Environment(AppStore.self)`. Use `@Bindable var store = store` inside `body` for bindings. |
| Data | `Core/MockData.swift` seeds everything; `AppStore` mutators are the future API seam. Persistence = one Codable `Snapshot` in `UserDefaults` (`AppStore.defaultsKey`). If you change `Snapshot`, bump the key version. |
| Navigation | Per-tab `NavigationStack(path:)` in `App/MainTabView.swift`; all pushes use `NavigationLink(value: Route.…)`; destinations registered once in `withQueslyRoutes()`. Add new screens as a `Route` case + destination, not ad-hoc `navigationDestination`. |
| Root flow | `RootView` in `App/QueslyApp.swift`: Welcome → onboarding steps → DailyQuestion (gate) → MainTabView. |
| Design tokens | `Core/Theme.swift` (`DS.Space`, `DS.Radius`, `Color.q*`, `Font.ui`, `Font.display`, `Animation.qSpring/qSmooth`). Icons: `Components/Icons.swift` (`QIcon` + `Icon`). |
| Demo / screenshots | `Core/DemoConfig.swift` reads `QUESLY_SCREEN` (DEBUG only) to open a screen with seeded state. Every new screen or state must get a demo case (see visual-qa). |
| Toolchain | **No Swift compiler or Simulator in this environment** (Linux container; the user is on Windows). The only compiler is the GitHub Actions macOS runner (`.github/workflows/ios-build.yml`). |

## Rules

1. **Compile-safety first.** Because you cannot build locally, write conservative Swift:
   - Use APIs available in **iOS 17** only. Guard anything newer with `if #available`. Known traps already hit here: `Color.mix(with:)` is iOS 18; `CGFloat`×`Double` math inside `cos/sin` needs explicit `CGFloat(...)`.
   - Enum raw values must be unique (bit us in `QIcon`).
   - Prefer explicit types over clever inference in large `ViewBuilder` bodies; split views >80 lines into subviews to avoid type-checker timeouts.
   - Don't use tuple key paths (`\.user.id` on tuples); make a small `Identifiable` struct.
   - `Text + Text` concatenation is deprecated on newer SDKs — use `AttributedString` or `HStack`.
2. **State ownership.** Screen-local UI state = `@State private`. Shared/domain state lives in `AppStore`. Never duplicate domain data in views except deliberate snapshots (e.g. lists that must not reorder while the user taps Follow) — comment why.
3. **Tokens only.** No raw hex, font sizes outside `Font.ui/.display`, corner radii outside `DS.Radius`, or spacing off the 4-pt grid. If a token is missing, add it via design-system-architect rather than inlining.
4. **Icons only through `Icon(QIcon.x)`** or `Label(…, systemImage: QIcon.x.rawValue)`.
5. **Motion.** Use `.qSpring` for interactions, `.qSmooth` for transitions. Any looping or decorative animation must check `@Environment(\.accessibilityReduceMotion)`. No `repeatForever` except loading indicators.
6. **Accessibility is part of "done":** every icon-only control has `accessibilityLabel`; custom controls get `.accessibilityAddTraits(.isButton/.isSelected)`; hit targets ≥ 44 pt (`DS.hitTarget`); text uses `Font.ui` so Dynamic Type works.
7. **Haptics** via `.sensoryFeedback` tied to real state changes, not to every tap.
8. **Preserve behaviour.** Before refactoring a view, list what it does (actions, sheets, navigation, persistence) and confirm each still works after the change.
9. **Match the codebase style:** small private computed subviews, `// MARK:` sections, doc comments only where intent isn't obvious.

## Workflow for any code change

1. Read the files you will touch, plus `Theme.swift` and `Icons.swift`.
2. Make the change; grep for every call site of anything you renamed (`grep -rn "Name" Quesly`).
3. Self-review for the compile traps above (search your diff for `cos(`, `sin(`, `.mix(`, `Text(` `+`, iOS 18 APIs).
4. Add/extend a `DemoConfig.Screen` case for any new UI state.
5. Commit, push, then follow **visual-qa** to get the CI build result and screenshots. A red build is the first thing to fix.

## Quality bar (measurable)

- CI build: **0 errors**, no new warnings you introduced.
- 0 raw hex colors / literal font sizes / non-grid paddings added (`grep -nE "Color\(hex|\.system\(size|padding\([0-9]*[13579]\)" ` on the diff).
- Every new interactive element: label + ≥44 pt target.
- No feature removed without the user's explicit agreement.

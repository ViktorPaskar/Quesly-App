---
name: visual-qa
description: Screenshot-based visual QA for Quesly. Use after any UI change, before telling the user a change "looks good", when asked to show screens, or when a CI build finishes. Builds run on GitHub Actions (macOS runner + iOS Simulator); this skill fetches the real screenshots, builds contact sheets, and runs a structured review. Never claim visual verification without having opened the screenshots.
---

# Visual QA — Quesly

## Environment truth (read first)

- **This agent runs in a Linux container. The user works on Windows. Neither has Xcode or the iOS Simulator.**
- The **only** real build + render happens on **GitHub Actions** (`.github/workflows/ios-build.yml`, `macos-15` runner, Xcode 16): it builds for the Simulator, launches the app once per demo screen, takes screenshots, and publishes them to the **`ci-screenshots`** branch (plus an unsigned `Quesly.ipa` artifact).
- Therefore: *"verified visually"* means **you opened the PNGs from the `ci-screenshots` branch for the exact commit you pushed**. Anything else is "not yet verified" — say so explicitly.
- Screenshots are static first frames ~7 s after launch: animations, gestures (long-press tray, swipe), keyboard and haptics are **not** verified by them. State that limitation when relevant.

## How screens are captured

`Quesly/Core/DemoConfig.swift` maps `QUESLY_SCREEN=<name>` (DEBUG builds only) to seeded state + initial tab/route/sheet. The workflow loops over a list of names (`for screen in …` in the workflow). Current set:

`welcome findFriends notifyPrime question composer feed feedEnd tray feedError offline friends otherProfile share reactions discover notifications profile saved settings editProfile achievements`

Extra passes (same run): **`dark-<screen>.png`** (Dark appearance: question, feed, reactions, discover, notifications, profile, settings) and **`xl-<screen>.png`** (Dynamic Type *accessibility-extra-large*: feed, profile, settings). Review them with the same checklist; dark mode and large text are only "supported" once these pass.

**When you add a screen or a meaningful state** (empty, error, sheet, tray open…): add a `DemoConfig.Screen` case, wire it (tab/route/sheet), and append the name to the workflow loop. Otherwise it cannot be verified.

## Procedure

1. **Push** the commit. Note its SHA.
2. **Wait for CI** (don't poll in the foreground; run in background):
   ```bash
   .claude/skills/visual-qa/scripts/wait-for-ci.sh <sha>     # prints "<run_id> completed success|failure"
   ```
   If it fails, fetch the job log with the GitHub MCP tools (`actions_list` → `list_workflow_jobs`, then `get_job_logs`), fix the compile error, and repeat. A green check alone is not enough — confirm `** BUILD SUCCEEDED **` appears in the log when in doubt.
3. **Fetch screenshots** for that SHA and build contact sheets:
   ```bash
   .claude/skills/visual-qa/scripts/fetch-screenshots.sh <out_dir> <sha>
   python3 .claude/skills/visual-qa/scripts/contact_sheet.py <out_dir> --per-row 5
   ```
   `fetch-screenshots.sh` refuses to continue if the branch's README commit ≠ the expected SHA (a newer/older run would otherwise be reviewed by mistake).
4. **Open every contact sheet** (Read tool) and, for anything suspicious, the full-resolution PNG (1179×2556) or a crop.
5. **Review with the checklist below**; write findings as `screen — issue — evidence — fix`.
6. Fix, push, repeat until no ❌ remains. Then present to the user: send contact sheets (SendUserFile), list what changed, what is still weak, and what was *not* verifiable from static screenshots.

## Review checklist (score each screen)

**Layout:** ☐ nothing touches screen edges (≥ 20 pt margin) ☐ consistent left alignment ☐ 4-pt rhythm, no cramped or orphaned elements ☐ safe areas respected ☐ no truncated essential text (`…` on names, chips) ☐ no overlap/clipping.
**Hierarchy:** ☐ one obvious primary action ☐ ≤ 3 type sizes ☐ no duplicated information ☐ accent (lime) only on green, ≤ 1 accent region.
**Consistency:** ☐ same component looks identical across screens (buttons, pills, rows, headers) ☐ icon style/weight consistent ☐ radii from tokens.
**Content/states:** ☐ realistic data, no placeholder text ☐ empty/error states designed where reachable.
**Accessibility (visual proxies):** ☐ text contrast OK (no lime on white, no light-gray body text) ☐ targets visibly ≥ 44 pt ☐ icon-only controls are recognisable.
**Brand:** ☐ matches established direction (green/lime, calm white content screens, Outfit only for display).

Severity: ❌ broken/blocking · ⚠️ noticeably off · 💡 polish. Ship only with 0 ❌.

## Measurable exit criteria

- CI green for the reviewed SHA, screenshots fetched for **that** SHA.
- 100 % of demo screens opened and scored; 0 ❌; every ⚠️ either fixed or listed for the user.
- Report explicitly separates *verified from screenshots* vs *not verifiable statically*.

## Useful extras

- Before/after: keep the previous run's folder and compare side by side (`contact_sheet.py` accepts any folder).
- Dark mode and Dynamic Type passes already exist (see above). To cover another screen in them, add its name to the `dark`/`xl` loops in the workflow.
- The IPA artifact (`Quesly-ipa`) lets the user sideload on their iPhone from Windows (Sideloadly); real-device feedback from the user outranks screenshots.

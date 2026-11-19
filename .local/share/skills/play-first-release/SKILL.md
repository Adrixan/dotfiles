---
name: play-first-release
description: Automate the first (manual-only) Google Play Console release of a paid Android app: create the app, App content declarations, IARC rating, target audience, Data safety, store settings, store listing with translation, VAT-correct price, countries, production release and "Send for review", by driving Peter's logged-in Chromium over CDP. Use when Peter asks to publish, release, submit or set up a new app in the Play Console, or to continue the first-release wave of his apps.
---

# Play Console first release

Google allows the first upload of every app only through the Play Console UI (the Publishing API works from the second release on; kit `docs/play-release-automation.md`). This skill scripts that UI. Proven on Lernspiele Kids, Lernspiele Teens and Venomous Snake (2026-11-19).

## Authorisation and stops
- Peter's go of 2026-11-19 covers: accept Play App Signing (Google-generated key, the default), fill and submit the declarations from the app's `play/DECLARATIONS.md`, set the price from the price list, release straight to production and send for review without internal testing. Ask before applying it to apps outside the current wave.
- Stop and ask on: a declaration the DECLARATIONS file does not answer, a rating above the declared audience (never weaken a true answer), a missing price, a hash mismatch, a consent not listed above, any billable action.
- Logins are Peter's. Never type credentials.

## Setup (once per session)
1. Private config `~/sync/ai/play-console/config.env` (account ID, contact email, website, CDP URL, browser profile). Never copy it or the app specs into a public repo.
2. Start a visible Chromium with its own profile and a loopback-only debug port, then ask Peter to log in to Play Console in that window:
   `setsid nohup chromium --user-data-dir=$HOME/.local/share/play-console-chromium --remote-debugging-address=127.0.0.1 --remote-debugging-port=9333 --no-first-run https://play.google.com/console >/dev/null 2>&1 &`
   The Playwright MCP is headless with a throwaway profile and cannot be used for this. Close Chromium when the wave is done (the port gives any local process the Google session).
3. Verify the bundle: `cd ~/sync/play-releases/<app> && sha256sum -c SHA256SUMS`, and compare the AAB hash with the table in the first-release notes.

## App spec
One file per app in `~/sync/ai/play-console/apps/<code>.env` (see the existing ones): `CODE NAME PACKAGE TYPE(App|Game) LANG_LABEL L2_LABEL META LOCALES CATEGORY PRICE(gross EUR) UK(yes|no) AGES("13-15|16-17|18 and over") TEACHER(yes|no) PRIVACY TERMS IARC_CAT("Game"|"All Other App Types") IARC_OVERRIDES(lines "<question regex>=<answer>") AAB VC`. Values come from the first-release notes (Part C) and the app's `play/DECLARATIONS.md`, `play/PUBLISHING.md`.

## Run
`scripts/first-release.sh <spec> [step ...]` from the working directory (state and asset copies go to `.scratch/play-console/`, the app URL to `<code>.url`). Steps in order: `create content rating audience safety settings listing price countries release check submit`. Every step stops with `STOP:` on anything unexpected; fix it, then rerun from that step.
- Apps whose questionnaire has any "Yes" answer: first `DRY=1 first-release.sh <spec> rating`, read every question against DECLARATIONS.md (follow-up questions appear after a Yes), set the extra answers with `node scripts/q.mjs set <index> <label>`, then click Save and finish the step by hand or rerun it.
- One app at a time. Do not click in the same app in another browser while a step runs.

## Gotchas learned (2026-11-19)
- **Price is net of VAT.** "New price in EUR" excludes VAT; 2.99 became EUR 3.59 in Austria. The script enters P/1.20 for all countries, then P/(1+rate) per euro country until every EEA euro country shows P; non-euro EEA countries keep Play's rounded conversion.
- **Listing save:** "Change saved" does not always complete the dashboard task. The `check` step catches it; Peter fixed Sudoku Grove with one more manual Save in the listing editor.
- **Asset order:** adding several screenshots in one panel action shuffles them, so the script adds one file per action. Copies get unique names (`<code>-<lang>-<slot>-<n>.png`) because the asset library is shared by all apps.
- **Translation graphics:** a translation inherits the default language's graphics; the script replaces icon, feature graphic and screenshots only where the files differ.
- **Country checkboxes:** a click sometimes does not register (Germany twice); the script re-checks every country and the targeted count.
- **IARC:** questions appear progressively and some groups ignore the first click; the script loops until every question has an answer. "Reference, News, or Educational" no longer exists: education apps use "All Other App Types" plus "primarily a news or educational product = Yes"; games use "Game".
- **AI asset declaration:** "Don't label assets" is correct for the kit apps (graphics rendered by repo scripts, screenshots from the app). Check this for other apps.
- **Target audience under 13** adds the Families certification, the Teacher Approved choice and the Families badge in Data safety; 13+ apps go straight to the summary.
- Managed publishing is off, so an approved app goes live automatically. The deobfuscation-file warning on release is harmless (no R8 mapping).

## After submitting
Tick the app in the first-release checklist (full app names, not short codes), record anything new under Gotchas here, and note the state in the kit's `.agents/session-handoff.md`.

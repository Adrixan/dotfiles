---
name: assignment-song
description: Write a fast, high-power song for one of Peter's school assignments (Digitale Grundbildung, Informatik, Kurse): German lyrics with performance hints plus Suno style instructions, with a genre chosen to match the assignment's theme. Explains the core task, the Vertiefung and why the topic matters; skips folder creation, saving and hand-in. Use when Peter asks for a song, Lied, Unterrichtssong or Suno track for an assignment, unit, Einheit, Aufgabe or "this week's" lessons.
---

# Assignment song

Turns one assignment from `~/Obsidian/Adrixan/Teaching` into a song in the format of the Music project (`~/Obsidian/Adrixan/AI/Claude.ai/Projects/Music`, abbreviated `Music/` below; save there whatever folder you were started in): **1) lyrics with hints, 2) style instructions for Suno** (Peter's standing order, 2026-11-08). Reference example of the target sound and depth: `references/example.md` ("Du bist das Produkt", Peter 2026-11-09: "an example of how such songs could sound").

Read first: `Music/Music.md`, `Music/Wissen/Suno.md` (prompt rules, Schlager trap, free-plan limits) and `Music/Memory/Präferenzen.md`.

## 1. Pick the assignment

- Peter names a unit or path: use it.
- Peter says "this week", "eine Aufgabe dieser Woche" or names no unit: call `mcp__ptsd__get_schedule` for the current Monday to Friday. Pick one unit and say why. Prefer a unit that runs in several classes, still lies ahead this week, and has a theme with an emotional hook (conflict, risk, surprise). Name the classes and dates.
- Unit folders: `Teaching/diggb/DIGGB_<k>_Klasse/<NN_name>/`, `Teaching/informatik/Informatik_5_Klasse/<NN_name>/`, `Teaching/Kurse/<kurs>/...`. Read only; never change anything in `Teaching/`.

## 2. Extract the content

Read in the unit folder:
- `Aufgabenstellung.md`: core steps, the "Schon fertig?" Vertiefung, sources.
- `Detaillierte_Stundenplanung.md`: "Das Warum?", Lehrziele, Leistungsfeststellung (what the Kernaufgabe and Vertiefung grade), KI-Reflexion question, phase plan.
- `Materialien/`: the actual content. `.docx`: unzip `word/document.xml` and strip tags (`python3 -I`); `.pdf`: `pdftotext -layout`; `.xlsx`: read with openpyxl via `uv run --with openpyxl`.

Write down: the concepts the core task needs, the exact Vertiefung task, the "why" for students' lives, and any fixed solutions (fact checks, quizzes, find-the-error tasks).

## 3. Scope and spoilers

- In: core task, Vertiefung, why the topic matters (use the unit's "Das Warum?" and the reflection question).
- Out: OneDrive folders, `Angabe/Materialien/Abgabe`, copying templates, `Strg + S`, PDF export, ZIP, Teams upload.
- Comprehension tasks (explain, describe, give examples): the song may carry the concepts. Say so in the note and recommend where to play it (Einstieg during the Impulsvortrag, or Sicherung after the hand-in).
- Tasks with fixed solutions (spot the 3 invented claims, quiz answers, error hunts): never reveal the solutions. Use invented examples that are not on the worksheet.
- Age: DIGGB 1 to 2 (10 to 12 years) short words and concrete images; DIGGB 3 to 4 and Informatik 5 (13 to 15) sarcasm and attitude are fine. No student names, no real classes beyond the schedule, no brand names of platforms when a generic word works ("die App").

## 4. Match the style to the theme

Always fast and high power: at least 125 BPM (most genres 150 to 190), instant full-band start on the first beat, no fade-in, no slow section, a breakdown that keeps the pulse, hard-stop ending. Peter chooses no tone; you choose one that fits the theme and justify it in one sentence. Starting points in `references/style-map.md`.

German lyrics are the default. German works naturally in punk, hardcore, Neue Deutsche Härte, metal, Deutschrap and drum and bass. German disco or dance-pop in a major key with even couplets, "Hey!" shouts, belting, brass and a key change up sounds like Schlager (Peter rejected "Stimmt oder erfunden" for this). For dance genres, either use the anti-Schlager measures from `Music/Wissen/Suno.md` or ask whether English is fine (English worked for "Fact or Fake"). Always put `schlager, volksmusik, polka, accordion, eurovision` in Exclude styles.

## 5. Write the lyrics

- Structure: `[Intro]` (gang shout or riff, 4 bars), `[Verse 1]`, `[Pre-Chorus]`, `[Chorus]`, `[Verse 2]`, `[Pre-Chorus]`, `[Chorus]`, `[Bridge]` (rapid-fire list of the key terms works well), `[Breakdown]` (Vertiefung), `[Build-Up]` (why it matters, "du entscheidest"), `[Final Chorus]` (variant line that turns the problem into control), `[Outro]` (hard stop), `[End]`.
- Every section gets one bracketed performance line: instruments, vocal delivery, energy, "no tempo change".
- Hook: a short phrase from the assignment itself, ideally its core sentence ("Wenn du nicht bezahlst, bist du das Produkt").
- Round brackets for gang or answer vocals; call-and-response makes terms stick.
- Spell numbers, keys, abbreviations and file names the way they should be sung ("Steuerung C", "Pe-De-Eff", "U-R-L").
- Suno moderation (it rejected "Lies das Datenblatt" v1 and accepted v2, 2026-11-15): never spell an abbreviation phonetically when the spelling forms a loaded acronym (SSD as "Es-Es-De" reads as SS; same for SA, KZ, NS); leave such abbreviations as written. No trademarked names, not even phonetic ("U-Es-Be", "Ha-De-Emm-I"): describe what the thing does. Avoid words with a violent meaning in German German even when harmless in Austrian ("angreifen" for touching: use "anfassen"). Details: `Music/Wissen/Suno.md`, section Moderation.
- Terms exactly as the material uses them, so students recognise them in the worksheet.

## 6. Suno instructions

Same block every time:
- Styles field full and compact version, each with its character count (count with Python, never estimate).
- Exclude styles (Schlager list, slow tempo, half-time, fade-out, genre opposites).
- No genre jargon in Styles or performance tags that is also a slur or insult in English ("skank beat": write "fast hardcore punk beat").
- Vocal gender, Weirdness (usually 25 to 35 %), Style influence (80 to 90 %), Audio influence (not used), Song title.
- Iteration tips: discard versions with a soft start, fixes for tempo drift and mumbled key terms, target length 2:45 to 3:30.
- A ranked table of three style directions (energy, how well German works, Schlager risk, estimated Suno reliability marked as untested) with a one-paragraph rationale.
- Peter has a free Suno plan: about 50 credits a day, older model, non-commercial use with attribution. Do not rely on Personas, Cover or Replace Section; give a "generate again" fallback.

## 7. Deliver and file

- Reuse first: if the unit (same PTSD lessonPlanId or unit folder) already has a song in `Music/Artifacts/` (frontmatter `assignment`), do not write a new one; add the new classes and dates to its `classes` frontmatter and to its "Einsätze" line in `Music/Artifacts/Songs/Produced.md`.
- New song: write `Music/Artifacts/Songs/KW<nn>/<YYYY-MM-DD> <class> <unit>.md` (frontmatter: title, date, type `song`, week, assignment path, lesson_plan_id, classes, tracker link, tags). It starts with `## Für Suno kopieren`: separate code blocks under `### Title`, `### Lyrics`, `### Suno style` (full version), then `### Weitere Felder` with Exclude styles and the compact style as code blocks and the sliders in one line, so each copies with one tap in Obsidian on the phone. Then: why this tone, didactic note (spoilers, where to play it), `## 1. Liedtext mit Hinweisen` (pronunciation notes and a table "Wo der Text die Aufgabe abbildet": task part, content from the material, place in the song; the lyrics stay only in the copy block), `## 2. Style-Anweisungen für Suno` (character counts, iteration, ranked style table).
- Several units at once ("this week"): also write `Music/Artifacts/Songs/KW<nn>/KW<nn> Übersicht.md` (every lesson with date, time, class, unit, song link, new or reused, and a production order within the free plan's daily credits) and add every new song as an unticked line to `Music/Artifacts/Songs/Produced.md` (Peter ticks it after producing it in Suno, link after "Suno:").
- Update `Music/Music.md` (Weiterarbeiten line and Inhalt table), the dated chat note in `Music/Chats/`, and `Music/.agents/session-handoff.md`.
- In the chat: the chosen unit with classes and dates, the tone and why, the full lyrics block and the full Suno block, and any spoiler warning.
- After Peter generates a version and saves it to `~/Music`, offer to measure it (tempo, key, energy curve; `Music/Wissen/Audioanalyse und Nightcore.md`) and adjust the tags.

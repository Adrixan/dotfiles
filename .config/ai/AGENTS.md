# AI Workstation Rules
Shared by Claude Code, Antigravity (agy) and OpenCode, configured to behave identically; no other harness is used. This file is public: private setup details live in the knowledge map included at the end.

## User
- Peter Aufner, peter@code-alongsi.de, Graz, Austria (CET/CEST), born 1989-04-15, Austrian; German native, English C2.
- Triad: person (digital garden, systems philosophy, stoic discipline as the prerequisite for personal and digital freedom, ultrarunning, endurance); educator "Prof. Aufner" (AHS teacher for CS and Digitale Grundbildung: patient structured scaffolding, Deeper Learning, Scrum/Kanban in school); business Code-Alongside (independent IT and infosec consulting: infosec, threat modeling, security architecture, automation, deployment stability, digital sovereignty).
- Role boundaries: pedagogical = curriculum design, agile learning, engagement, digital literacy, concept translation, professional relevance for youth. Consulting = no pedagogical overhead; deployment stability, script efficiency, zero trust, compliance (EU AI Act, GDPR, ISO 27001). Gray area: turn enterprise vulnerabilities into safe open-source classroom labs.
- Life: 04:30 wake-up, vegan, daily strength training (lean athletic build) plus endurance (elliptical, ergometer, long mountain hikes, ultrarunning); tent camping, vanlife, Austrian rough terrain; black functional gear (Arc'teryx LEAF style).
- Interests: cyberpunk, solarpunk, classic anime/manga, goth, metal, hacker culture, astronomy, science, international and Austrian politics; hard sci-fi; terminal/mobile interactive fiction (cyberpunk, solarpunk, gothic themes); retro gaming only on Android.
- Freelance CV, target roles and application rules: skill `freelance-profile` (load it for applications, CVs, rates, pitches).

## Environment
- Machines: schulpc (always-on desktop), laptops m11x and xps13 (openSUSE Tumbleweed, Zsh; Zypper packages, Docker services, Flatpak GUI apps); Android phone with Termux.
- Sync root: `~/sync` (Syncthing); in Termux `~/storage/shared/sync`. Every `~/sync/...` path in these rules maps to it. Self-hosted Nextcloud; Netcup web hosting (PHP, MySQL, cron).
- PKM: atomic Markdown, moving to automated stream processing (RSS, ingestion, sorting scripts, cron).
- Scratch: scripts, test runners, temp data and debug tools only in `.scratch/` of the working dir, never `~/.claude/`, `~/.gemini/` or `/tmp`. Non-code notes go to the working dir or the Obsidian vault.
- Knowledge map: private `~/sync/ai/WORKSTATION.md`, inlined below. Use it for the Ph.D. vault, educator brand, teaching, edu-publisher, Ansible, hosting and harness config; never copy its content into public repos; update it when a setup changes.
- Projects: rules in the root `AGENTS.md`; `CLAUDE.md` contains only `@AGENTS.md`. Skills: project `.claude/skills/<name>/SKILL.md`; global `~/.claude/skills` (relative links into `~/.local/share/skills`), read natively by Claude Code and OpenCode, by Antigravity via `~/.gemini/config/skills.json`. New global skill: folder in `~/.local/share/skills` plus a link in `~/.claude/skills`, never a harness folder.
- Handoff: write `.agents/session-handoff.md` (trajectory, intent, open decisions, next steps) after non-trivial tasks and before exit; read it and the other `.agents/` state files first in any directory. Asked to stop in an rc role session (`RC_DIR` set; by the Greeter or by Peter): write the handoff, run `rc handoff-done` (add `--stop` when Peter told this session directly), end the turn with one short line; the role stops seconds later.
- Knowledge: standing orders and project rules go into the project `AGENTS.md`, current state into `.agents/`, cross-project setup into the knowledge map, entity facts into the shared MCP `memory` graph; never into harness-private stores (Claude auto-memory, Antigravity knowledge items), so every harness reads the same.

## Branding: Bioluminescent Night
- Default for all UI, web pages, components, CSS and brand assets; full guide `~/.config/ai/BRANDING.md`.
- Archetype The Architect (sustainable sovereignty: systems thinking, discipline, solarpunk). Tech-wear professional: functional, minimalist, clean lines, dark mode default, generous negative space, subtle glassmorphism (`backdrop-filter`).
- Colours: base #121212 Void Charcoal (no pure black); panels #1E1E1E Deep Slate; text #E0E0E0 Starlight Grey; primary #4ADE80 Digital Fern (active states, CTAs, links, Code-Alongside); secondary #A7F3D0 Cyber-Mint (educational highlights, pedagogical badges); alert #F59E0B Signal Amber (warnings, security advisories).
- Fonts: headings Space Grotesk or Chakra Petch; body and UI Inter or Public Sans; code JetBrains Mono.

## Epistemics
- Honest opposition: challenge flawed premises, invalid assumptions and weak technical choices; never agree out of politeness.
- No praise, compliments or filler ("good question", "great point", "you are right"); start with substance.
- Ground technical and scientific claims in verifiable findings; without consensus state origin and uncertainty; never fabricate sources; cite literature inline with full references.

## Output
- Metric units only. Never use em dashes (use colons, parentheses, semicolons, periods). No contrastive or corrective metaphors ("X is not Y, it is Z").
- Deep research reports: TL;DR first, overview table last; comparisons end with a table; rank feasible options with an evidence-based rationale.
- Continuous line flow, no blank line before lists, unnumbered bullets unless order matters.
- Length: comprehensive and dense by default; suffix `s` = short, `m` = medium.
- No preambles, prompt restatements or sign-offs; thinking depth matches task and suffix; never show internal or system XML tags.

## Engineering
- Priority: Security > Correctness > Accessibility > Performance > Maintainability > Style.
- Code: minimal, readable, strictly typed, secure by default (OWASP, CIS); no hardcoded secrets; DRY from the third occurrence.
- Triage: trivial (typos, small config) = do it; existing codebase = follow its conventions; non-trivial = clarify requirements, assumptions and open questions first; managed mode = Agile/TDD story loop with `.agents/` state files (`project-state.md`, `plan.md`, `to-do.md`) when present.
- Dependencies: latest stable release only (libraries, frameworks, tools, images, CI actions), looked up in the registry (PyPI, npm, Packagist, crates.io, Docker Hub, GitHub releases), never from memory. No known vulnerabilities: check OSV and GitHub advisories and run the ecosystem audit (`pip-audit`, `npm audit`, `composer audit`, `cargo audit`, `osv-scanner`) before committing; if the latest release is affected, use a fixed release or an alternative and report it. Supply-chain cooldown: install only releases published at least 24 hours ago ("latest" means the newest release past the cooldown; `min-release-age=1` in `~/.npmrc` and `/usr/etc/npmrc`, `exclude-newer = "24 hours"` in uv, `minimumReleaseAge: 1440` in pnpm, `cooldown: default-days: 1` in Dependabot). Audit findings without a fixed release need Peter's acceptance, recorded in the repo (e.g. `audit-exceptions.json`) with the reason. No exact pins: manifests and install specs name the latest release as the minimum (`>=x.y.z`, `^x.y.z`, `latest`), a cap or pin only where a newer release is known to break or a format needs it (comment the reason); lockfiles only record the resolution and are refreshed to the latest releases (`uv lock --upgrade`, `npm update`) whenever dependencies are touched; no pre-releases unless asked; major upgrades in existing projects need approval.
- Approval: never drop scope, pivot or make breaking architectural changes without explicit approval.
- Debug: after two failed attempts stop, re-check assumptions, present alternatives with trade-offs.
- Loop: DISCOVER (inspect) > DECIDE (security, scope) > ACT (minimal change) > VERIFY. Deliver complete, runnable code, no placeholders or `# TODO` unless asked. Validate inputs, sanitize boundaries, handle errors explicitly, follow openSUSE/Zsh/Docker conventions.
- Git: after a verified change commit and push without asking (Conventional Commits). On `main`/`master`: feature branch, push, `git pull --ff-only` on the default branch, `git merge --no-ff`, push. Work on an existing long-lived branch (e.g. `laptops`) stays there; merging it needs approval. Never commit secrets or force-push; never pipe `git push` into `tail` or `grep` (it hides failures); delete a source branch only after its commits are verified on the remote; stop and report failing hooks, tests, push or merge (`git merge --abort` on conflicts).

## Knowledge map
<!-- Claude Code imports whichever path exists (desktop or Termux); Antigravity uses the absolute include; OpenCode loads it via `instructions` in opencode.json. -->
@~/sync/ai/WORKSTATION.md
@~/storage/shared/sync/ai/WORKSTATION.md
@[knowledge map](/home/Adrixan/sync/ai/WORKSTATION.md)

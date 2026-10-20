# Session Handoff: AI Workstation Dotfiles in Yadm

## Trajectory
- Inspected dotfile status and existing tracked configurations in yadm.
- Discovered that the remote repository `Adrixan/dotfiles` is public on GitHub.
- Audited all AI harness configuration files across Claude Code, Gemini CLI (Antigravity), OpenCode, and Copilot.
- Identified sensitive secrets (GitHub Personal Access Tokens, NowCoding API keys, OAuth credentials) and local machine state (databases, chat histories, session logs, dynamic caches).
- Registered the git-based skill extension (`.local/share/skills/ELI5`) as a yadm submodule.
- Unloaded duplicate skill directories in `.claude/skills` and replaced them with unified symlinks pointing to `.local/share/skills/`, matching `.gemini/skills/` and `.config/opencode/skills/`.
- Converted sensitive configs (`.gemini/config/mcp_config.json` and `.config/opencode/opencode.json`) into yadm templates (`##template`) referencing environment variables (`GITHUB_PERSONAL_ACCESS_TOKEN`, `ANTHROPIC_WORKSPACE_ID`, `NOWCODING_API_KEY`) and dynamic paths (`{{ env.HOME }}`).
- Configured comprehensive exclusion rules in `.config/git/ignore` to prevent leaking machine-local files, session databases, or tokens.
- Staged and committed all CLI-relevant, portable configuration files and submodules to yadm.
- Applied `~/Obsidian/Adrixan/Claude System Context.md` into the canonical global instruction file `~/.config/ai/AGENTS.md`, merging it with existing cross-harness engineering and session-continuity standards.
- Standardized relative symlinks across all global AI harnesses (`~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, `~/.config/opencode/AGENTS.md`, `~/.agents/AGENTS.md`, `~/.copilot/copilot-instructions.md`, `~/AGENTS.md`, `~/CLAUDE.md`) pointing to `~/.config/ai/AGENTS.md`.

## Active Intent
Maintain a portable, secure, conflict-free multi-harness AI workstation configuration across devices via yadm.

## Pending Decisions & Next Steps
- On secondary machines: run `yadm pull`, `yadm submodule update --init --recursive`, and `yadm alt` to instantiate the templated MCP and OpenCode configs.

## 2026-10-18: MCP stack overhaul (ansible US-14.1)
- yadm is the single owner of harness MCP configs: Claude Code plugin marketplace `~/.config/ai/claude-plugins` (enabled via `~/.claude/settings.json`), `~/.gemini/config/mcp_config.json##template`, `~/.config/opencode/opencode.json##template`.
- Binaries, secrets file and template rendering come from `~/code/ansible-opensuse-server` role `ai_workstation` (`ansible-playbook main.yml -e enable_ai_workstation=true`).
- New machine: `yadm clone`, then run the playbook (it renders templates with secrets and registers the Claude plugin). Never run `yadm` commands in a shell without `~/.config/ai/env` sourced: auto-alt renders blank secrets.
- Pending: Nextcloud credentials (see ansible repo handoff).
- NowCoding provider removed from OpenCode and the ai_workstation role (2026-10-18).
- Rule change (2026-10-18): `auto_commit_and_push` in `~/.config/ai/AGENTS.md` now merges feature branches back into `main`/`master` automatically (`pull --ff-only`, `merge --no-ff`, push). Long-lived non-default branches (e.g. ansible `laptops`) are not merged without approval.
- `feat/mcp-stack-overhaul` merged into yadm `master`.

## 2026-10-19: Applying `~/Claude-cli-desktop.md` (step-by-step)
- Re-evaluated the report for all five domains: PhD (`~/Obsidian/Ph.D.`), Educator social (`~/Obsidian/Adrixan/Educator`), Teaching (`~/Obsidian/Adrixan/Teaching`, `~/Documents/Unterricht`, PWA repos), Freelance (`~/code/*`), Travel/life (Desktop + claude.ai connectors). The report's `~/workspace/` layout is rejected by the user.
- Step 1 done: `cleanupPeriodDays: 365` in `~/.claude/settings.json` (yadm). "Help improve Claude" training setting confirmed OFF by the user on 2026-10-19.
- Remaining steps, in order:
  2. DONE 2026-10-19: per-client deny file (user chose fail-open helper over a split plugin). Policy `~/.config/ai/client-settings.json` denies `plugin:workstation-mcp:{memory,nextcloud,zotero,arxiv,serena}` and sets `disableClaudeAiConnectors`; GitHub stays allowed. Run `claude-client-init <repo>` in every new client repo/worktree (`--check` verifies). Verified: settings do not inherit from parent dirs; `deniedMcpServers` needs the full `plugin:<plugin>:<server>` name. No client repos exist yet.
  3. DONE 2026-10-19 (PhD). 3a `ocrmypdf` via Ansible (laptops, e93ddcb). 3b Zotero 10.0.6 + Better BibTeX 9.0.71 as reference source of truth; Zotero MCP write key in `~/.config/zotero-mcp/config.json` (yadm-ignored). 3c P1 screening/charting: user chose autonomous Claude screening with blind human audit of exclusions (over agent's first proposal of Claude as second screener); `Scripts/p1_review.py` + skills `screen`/`extract`. Details: `~/Obsidian/Ph.D./.agents/session-handoff.md` Session 9. Open for user: delete the staging auto-export in Zotero, fix 3 ambiguous author names.
  4. DONE 2026-10-19: `claude-remote-control@{phd,teaching,educator}.service` (Ansible `ai_workstation/tasks/remote_control.yml`, laptops branch), permission mode auto, one server per directory (the app cannot pick directories; home dir trust is not persisted). Manual LUKS unlock kept by user choice, so servers return after the user unlocks a reboot. schulpc is the user's own hardware. Consent key in ~/.claude.json: remoteDialogSeen.
  5. DONE 2026-10-20: Educator workspace (`CLAUDE.md`, skills edu-research/write/repurpose/script/publish) and the publisher `~/code/edu-publisher` (private GitHub repo since 2026-10-20). Full PHP port runs on aufner.org: code `~/edu-publisher`, data `~/edu-publisher-data` (outside docroots), Plesk cron */5 on PHP 8.5.9, deployed with `./deploy.sh` (tests on server PHP 8.0 first). Workstation runs `edupub sync` (Ansible role `edu_publisher`): pushes approved pieces, converts images per platform, pulls state. Live-tested: Telegram handoff, YouTube (private upload), Instagram (story), Bluesky, Threads, Facebook Page (934007819804051). Telegram channel (t.me/Prof_Aufner/3). Not live-tested: YouTube scheduled publishAt (first real scheduled video). Handoff only: TikTok, WhatsApp channel, X (pay-per-use, the SpaceX/xAI bundle covers the Grok API, not X posting), Pinterest, Giphy. schulpc's network blocks Meta and Bluesky, so `edupub auth instagram|threads|facebook|bluesky` only forwards credentials and the server talks to the platforms. Security follow-ups: two Instagram tokens and the Instagram app secret were pasted into the chat transcript (rotate the app secret); all sites of the hosting account share one system user. Newsletter undecided.
  6. DONE 2026-10-20: BRG Petersgasse CD 2026 (from `CD_Richtlinien_2026 3.pdf`) rolled out to all Typst materials. Single source `~/Obsidian/Adrixan/Teaching/templates/cd_petersgasse.typ` (colours, Source Sans 3, `cd-logo` = MINT-Fächer logo, `cd-credit` = '© year Peter Aufner · peter.aufner.org'; prof.aufner.org removed on request). 12 logos extracted (SVG/PDF vector + 2400 px PNG) to `Teaching/templates/logos/` with README and `extract_logos.sh`. 10 themes, 4 generators, material tools and the Jahresplanung switched; Typst root is now Teaching/. Regenerated 584 .typ (content check against backup: only design diffs, 0 unexpected), rebuilt 288+72+30+195 PDFs plus 4 workshop PDFs, 55 material PDFs (material tools ran in a scratch copy so no Office file changed) and 8 Jahresplanungen (restyled in place, schedules untouched). Office (Word/Excel/PowerPoint) deliberately untouched per user. Backup: /backup/schule/teaching-backups/teaching_vor_cd_rollout_2026-10-20.tar.zst. User to delete stale `templates/logos/brg-petersgasse_logo_farbe_adresse.{svg,pdf,png}` (rm was blocked by the safety check). Open: Office CD (later), draw.io template colours in informatik/tools/materialien.py (left as is), § 46 SchUG note on personal links in school materials.
  7. DROPPED 2026-10-20 by user: no Zellij layout/launcher (remote-control servers from step 4 cover phone access).
- Side issue FIXED 2026-10-20: grml `chpwd` now uses `${DIRSTACKSIZE:-20}` (shells that only inherit the function, e.g. Claude Code shell snapshots, lack the variable). Snapshots taken before the fix still print the error until the next session.

## 2026-10-20: Shared knowledge for all harnesses
- Private knowledge map `~/sync/ai/WORKSTATION.md` (mode 600, Syncthing to all devices; machines, network block, config ownership, Claude Code setup, PhD, educator/publisher, teaching CD, open items). Pointer `knowledge_map:` in `~/.config/ai/AGENTS.md`; never copy its content into the public dotfiles or Ansible repos. Update it when a setup changes.
- Convention `project_context:`: project rules in `AGENTS.md`, `CLAUDE.md` contains only `@AGENTS.md`, skills listed in the project AGENTS.md for harnesses without skill support. Applied to Ph.D. (merge 4d900c6), Educator, Teaching (new AGENTS.md), edu-publisher. Gemini CLI reads AGENTS.md via `context.fileName` in `~/.gemini/settings.json`. Verified with headless `claude -p` probes in Ph.D., Educator and Teaching.
- New global rule `dependency_policy:` (latest stable only, registry lookup, no known vulnerabilities, exact pins, major upgrades via approval_gates). Mirrored into the Ansible seed template `roles/ai_workstation/templates/AGENTS.md.j2` (laptops ccedadd). yadm merge 05c7c1b.
- edu-publisher: private GitHub repo `Adrixan/edu-publisher` (AGPL-3.0, history secret-scanned); Ansible role `edu_publisher` clones it (laptops 19e28b5). Code was already in `~/code/edu-publisher`, so it was not moved.

## 2026-10-19: OpenCode on DragTokens (ansible US-14.2)
- yadm `~/.config/opencode/opencode.json##template`: provider `dragtokens` (`@ai-sdk/openai`, `https://dragtokens.com/v1`, key `{{ env.DRAGTOKENS_API_KEY }}`); plan agent `gpt-6-astra`, build agent `gpt-6.1-sol` (`gpt-6-sol` also listed).
- `DRAGTOKENS_API_KEY` lives only in `~/.config/ai/env` (0600, Ansible-managed) and the rendered `opencode.json` (0600, untracked). OpenCode binary: native `~/.opencode/bin/opencode` from the `ai_desktop` role.
- Pending: live call untested (dragtokens.com blocked by the FortiGuard DNS filter on the current wired network). Decide whether DragTokens may ever see client code (see the ansible handoff).

## 2026-10-19: OpenCode 2 (ansible US-14.3)
- OpenCode 2.0.32; updates are handled by the `ai_desktop` role plus a daily timer. yadm `opencode.json##template` stays in V1 format (V2 reads it); removed the V1-only `plugin` (opencode-yolo) and the ignored `server` block; `/yolo` command deleted. Use `opencode --auto` for auto-approval.
- `~/.config/opencode/service.json` (V2 server password) is git-ignored.

## 2026-10-19: OpenCode native V2 config
- `opencode.json##template` is native V2 (`providers`, `agents`, `mcp.servers`, `update: auto`). After `yadm pull` on a machine still on V1, run the ansible playbook immediately (V1 cannot read this shape).
- DragTokens unreachable on the school network (FortiGuard DNS + SNI filter); see ansible handoff US-14.4.

## 2026-10-20: Harness parity (Claude Code, Antigravity, OpenCode), Copilot and Kilo removed
- Agent instructions and skills are tracked only in yadm. Ansible (`laptops` 73440c4) no longer has `instructions.yml`, `skills.yml` or the AGENTS.md seed template; check-mode run clean.
- Copilot and Kilo removed: `~/.copilot`, the `copilot-instructions` and `kilo-glm5-instructions` submodules with their symlinks, `.kilocode`, `.copilot`, `.github/{agents,skills,instructions}`, GLM `agents.md` in 22 repos under `~/code` (merged into `main`; feature branches peter.aufner.org, code-alongsi.de, Cast-Game and ansible `laptops` keep their commits unmerged). Untracked remnants moved to `/backup/ai/`. The GitHub repos `Adrixan/copilot-instructions` and `Adrixan/kilo-glm5-instructions` still exist.
- Same inputs in all three harnesses, verified by headless probes: global AGENTS.md plus the private knowledge map (Claude `@~/` import, Antigravity `@[..](abs)` include, OpenCode `instructions`), project AGENTS.md, skills from `~/.claude/skills` plus project `.claude/skills` (Antigravity via `~/.gemini/config/skills.json##template`), same MCP set. Antigravity skill bundle removed.
- Next: keep the global AGENTS.md plus knowledge map under Antigravity's 24 KB per-rule-file cap (about 22.6 KB now).
- Follow-up 2026-10-20: global AGENTS.md compacted (rules plus knowledge map 22.6 KB to 13.7 KB); CV moved to the on-demand skill `freelance-profile`. Termux: sync root `~/storage/shared/sync`; templates branch on `env.TERMUX_VERSION`, Claude imports both paths. Skill links in `~/.claude/skills` are relative; `~/.config/opencode/skills` and `~/.gemini/skills` removed (single source `~/.claude/skills`). Antigravity Google plugins enabled again. `kilo-glm5-instructions` deleted on GitHub (`copilot-instructions` was already gone).

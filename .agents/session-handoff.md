# Session Handoff: AI Workstation Dotfiles in Yadm

## Trajectory
- Inspected dotfile status and existing tracked configurations in yadm.
- Discovered that the remote repository `Adrixan/dotfiles` is public on GitHub.
- Audited all AI harness configuration files across Claude Code, Antigravity and OpenCode.
- Identified sensitive secrets (GitHub Personal Access Tokens, NowCoding API keys, OAuth credentials) and local machine state (databases, chat histories, session logs, dynamic caches).
- Registered the git-based skill extension (`.local/share/skills/ELI5`) as a yadm submodule.
- Unloaded duplicate skill directories in `.claude/skills` and replaced them with unified symlinks pointing to `.local/share/skills/`, matching `.gemini/skills/` and `.config/opencode/skills/`.
- Converted sensitive configs (`.gemini/config/mcp_config.json` and `.config/opencode/opencode.json`) into yadm templates (`##template`) referencing environment variables (`GITHUB_PERSONAL_ACCESS_TOKEN`, `ANTHROPIC_WORKSPACE_ID`, `NOWCODING_API_KEY`) and dynamic paths (`{{ env.HOME }}`).
- Configured comprehensive exclusion rules in `.config/git/ignore` to prevent leaking machine-local files, session databases, or tokens.
- Staged and committed all CLI-relevant, portable configuration files and submodules to yadm.
- Applied `~/Obsidian/Adrixan/Claude System Context.md` into the canonical global instruction file `~/.config/ai/AGENTS.md`, merging it with existing cross-harness engineering and session-continuity standards.
- Standardized relative symlinks across all global AI harnesses (`~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, `~/.config/opencode/AGENTS.md`, `~/.agents/AGENTS.md`, `~/AGENTS.md`, `~/CLAUDE.md`) pointing to `~/.config/ai/AGENTS.md`.

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
- Convention `project_context:`: project rules in `AGENTS.md`, `CLAUDE.md` contains only `@AGENTS.md`, skills listed in the project AGENTS.md for harnesses without skill support. Applied to Ph.D. (merge 4d900c6), Educator, Teaching (new AGENTS.md), edu-publisher. Antigravity reads AGENTS.md (`context.fileName` in `~/.gemini/settings.json`). Verified with headless `claude -p` probes in Ph.D., Educator and Teaching.
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

## 2026-10-20: Harness parity (Claude Code, Antigravity, OpenCode), Kilo removed
- Agent instructions and skills are tracked only in yadm. Ansible (`laptops` 73440c4) no longer has `instructions.yml`, `skills.yml` or the AGENTS.md seed template; check-mode run clean.
- Kilo removed: the `kilo-glm5-instructions` submodule with its symlinks, `.kilocode`, `.github/{agents,skills,instructions}`, GLM `agents.md` in 22 repos under `~/code` (merged into `main`; peter.aufner.org, code-alongsi.de and Cast-Game merged into `main` on 2026-10-21; ansible `laptops` stays unmerged until approved). Untracked remnants were parked in `/backup/ai/` and deleted by Peter on 2026-10-21, together with `~/.bailian`.
- Same inputs in all three harnesses, verified by headless probes: global AGENTS.md plus the private knowledge map (Claude `@~/` import, Antigravity `@[..](abs)` include, OpenCode `instructions`), project AGENTS.md, skills from `~/.claude/skills` plus project `.claude/skills` (Antigravity via `~/.gemini/config/skills.json##template`), same MCP set. Antigravity skill bundle removed.
- Next: keep the global AGENTS.md plus knowledge map under Antigravity's 24 KB per-rule-file cap (about 22.6 KB now).
- Follow-up 2026-10-20: global AGENTS.md compacted (rules plus knowledge map 22.6 KB to 13.7 KB); CV moved to the on-demand skill `freelance-profile`. Termux: sync root `~/storage/shared/sync`; templates branch on `env.TERMUX_VERSION`, Claude imports both paths. Skill links in `~/.claude/skills` are relative; `~/.config/opencode/skills` and `~/.gemini/skills` removed (single source `~/.claude/skills`). Antigravity Google plugins enabled again. `kilo-glm5-instructions` deleted on GitHub.
- 2026-10-20 (later): serena, nextcloud and docker MCP enabled in OpenCode and Antigravity (yadm 319d088). New skills: Teaching `marp-slides` (CD theme from the Typst tokens), Ph.D. `docx-cite` (pandoc plus Better BibTeX). Ansible `office_suite` (laptops e6fde27, 618bd90): pinned Marp CLI with audited overrides, pandoc 3.12.1. User guides in `~/Obsidian/Adrixan/AI/`: `AI Workstation Cheatsheet.md`, `New Machine Setup.md`.

## 2026-10-21: claude.ai export imported into the Obsidian vault
- Export (manifest 2026-10-21 06:50 UTC) downloaded by Peter to `~/import/` (curl and headless Playwright are blocked by Cloudflare). Archive: `~/Obsidian/Adrixan/AI/Claude.ai/` with `_Index.md`, `Projects/<name>/` (project note with *Weiterarbeiten*, `Chats/`, `Wissen/`, `Memory/`, `Artifacts/`), `Chats/<year>/` for chats outside projects, `Memories/`, `Reflections/`. 42 chats, 8 projects; 4 empty chats and 2 unnamed starter projects skipped; login history and phone number not imported.
- The export has no project id per chat: mapping from memory paths and project_info calls ("belegt"); Reiseplanung (2 chats) and BIMM (2 chats) are inferred from topic and timing (`project_assignment: inferred`).
- Merged into local data: `Educator/strategie/` (roadmap, kennzeichnungspflichten, news-pipeline from 2026-10-08 with superseded-tooling banners, plus brand-briefing from the project instructions and memory) with a pointer in `Educator/AGENTS.md`; new subtree `Teaching/Doku-Petersgasse/README.md` plus a row in `Teaching/AGENTS.md`. Not merged (local is newer or identical): prof.aufner.org site files (repo 2026-10-13), agents.md (removed 2026-10-20), brand-strategy/socials/social_media_strategy_report (identical), Ph.D. project-state summary (vault 2026-10-19).
- Open for Peter: delete `~/import/` and the manifest in `~` once the import is checked (they hold the unredacted data); put the final Doku-Petersgasse Office files (only in claude.ai) into `Teaching/Doku-Petersgasse/`; answer the open comment on the Sparplan doc.

## 2026-10-21: One knowledge store for all three harnesses
- Claude auto-memory held 16 notes in 6 projects that Antigravity and OpenCode could not read. Content moved to shared locations: PTSD `AGENTS.md` + `CLAUDE.md` (merge 383c4bd), prof.aufner.org `AGENTS.md` + `CLAUDE.md` (local only, `*.md` is git-ignored there), Teaching `AGENTS.md` rules, knowledge map (aufner.org bot-UA IP ban, code-alongsi.de Nextcloud playground, list of shared knowledge stores), global AGENTS.md (`Knowledge:` rule, git push pipe pitfall). neon-core was already in `.agents/wissen/`.
- Claude auto-memory off (`autoMemoryEnabled: false`, yadm 2390171). Original note files archived read-only in `~/Obsidian/Adrixan/AI/Claude Code Memory/` (`_Index.md` maps each to its live location); `~/.claude/projects/*/memory/` is empty.
- OpenCode models unchanged by decision: TUI uses `agents` build `dragtokens/gpt-6.1-sol` and plan `dragtokens/gpt-6-astra`; top-level default `anthropic/claude-sonnet-4-5` has no API balance. `opencode run` uses the top-level default even with `--agent`, so headless probes pass `-m`.
- Harness names cleaned: Copilot mentions removed, Gemini CLI renamed to Antigravity (this handoff, knowledge map, neon-core `.agents` on MR !1 branch 17e18d6, wpengine-launcher, venomous-snake). The GitHub MCP URL `api.githubcopilot.com` is functional and stays.
- Verified with headless probes: agy in PTSD and Teaching/diggb, OpenCode in PTSD (with `-m dragtokens/gpt-6.1-sol`).
- Later: `ptsd` and `newspaper-testground` MCP servers added to the OpenCode template (copied from Claude's user scope in `~/.claude.json`; newspaper with 30 s startup and catalog timeouts). OpenCode service restarted; both connected, ptsd and newspaper tool calls verified. Antigravity still lacks both.

## 2026-10-21: MCP server scouting (mcpservers.org)
- Crawled mcpservers.org/all (16,455 of 16,667 entries) into `~/.scratch/mcpservers/catalogue.jsonl`; crawler `bin/crawl.py` (rate limit: 1.5 s/page), filters `bin/filter.py`, `bin/show.py`.
- Shortlist with GitHub metadata in the session answer; nothing installed or changed.
- Top picks: package-version-check-mcp, StacklokLabs/osv-mcp, `semgrep mcp` (built into semgrep; standalone repo archived), cyanheads/openalex-mcp-server, pho-research-tools, Excalidraw (yctimlin), drawio (lgazo), mcp-zap-server, MCPGoat/DVMCP labs, obsidian-hybrid-search.
- Next: Peter picks servers; install via Ansible `ai_workstation` plus yadm templates for all three harnesses; run audits before pinning.
- Gaps (build candidates): Austrian RIS, GeoSphere Austria, EAWS avalanche bulletins, ERIC, Typst compile.
- 2026-10-21 (later): Tier 1 servers except ZAP and labs are installed and live (ansible `laptops` 42cccbc, 5874bb2; yadm master 44b3f02). Details in the ansible repo handoff.
- 2026-10-21 (later): Tier 2 picks installed (lighthouse, accessibility, docs, nasa, open-meteo, openroute, wikipedia, searxng; plugin 1.3.0, yadm master 089a3da; ansible `laptops` 82f1387). Adrixan vault index skipped on schulpc for memory (ansible 6dda5b8). Details: ansible repo handoff and the knowledge map.
- Open for Peter: `NASA_API_KEY` (DEMO_KEY meanwhile) and `OPENROUTESERVICE_API_KEY` into `~/.config/ai/env`, then rerun `ai_workstation`; laptop rollout (`yadm pull`, then `ansible-playbook main.yml -e enable_ai_workstation=true`); merging ansible `laptops` into `master` needs approval.
- File Accountant question answered without code changes: `delete_open_bill` (TUI `d`, label "Delete Draft" undersells it) still deletes any unpaid bill and releases its entries; paid by mistake: `r` then `d`; sent: Storno `c`. A relabel would go through that repo's own session.

## 2026-10-23: `~/Free Claude MCP Servers.md` evaluated (deep-research report of 2026-10-18)
- Not covered by the 2026-10-21 mcpservers.org scouting; checked against the installed plugin set, Teaching notes (school LMS is MS Teams; Moodle only in ICDL references), and GitHub metadata.
- Result: no always-on additions. Already covered: memory, fetch, git, github, markitdown, serena, playwright, docker, arxiv, zotero (54yyyu 0.15.1 already does text-matched PDF highlights, outlines, page reads, so zoteus/cookjohn add nothing), Context7 (claude.ai connector) plus docs, searxng (replaces DuckDuckGo).
- Optional, on demand only: LaurieWired/GhidraMCP (Apache-2.0, 11.5k stars, needs Ghidra plus JDK; for infosec labs and RE engagements, project-scoped `.mcp.json`, not the global plugin); petersolopov/obsidian-claude-ide (MIT, Obsidian plugin, Claude-only `/ide` bridge, convenience).
- Rejected: Canvas/Moodle (not used), Proxmox/Kubernetes/Prometheus/Grafana/Netdata/Home Assistant (no such infra; client repos only if an engagement needs them), Google Calendar/Todoist/Apple/Spotify (Nextcloud covers it; sovereignty), Screenpipe (24/7 capture, GDPR on a school-adjacent machine), Sequential Thinking/Time/Filesystem/DesktopCommander (native in Claude Code), E2B (US cloud), claude-task-master (conflicts with `.agents/` loop), Jupyter servers (0 notebooks in use).
- Decision (Peter, 2026-10-23): install the Obsidian Claude IDE plugin (petersolopov 0.2.7) and the DuckDuckGo MCP (nickclyde, PyPI duckduckgo-mcp-server 0.7.0); GhidraMCP not now; everything else stays out. SearXNG removed as too resource-intensive.
- Done 2026-10-23: duckduckgo replaces searxng in all three harness templates (plugin 1.4.0; ansible `laptops` e456924), probes pass in all three. Obsidian plugin reviewed (loopback, token auth, no writes or network) and installed in `Ph.D.` and `Adrixan` vaults. Open for Peter: open each vault once in Obsidian (Ph.D.: turn on community plugins, restricted mode), then `/ide` in Claude Code; laptops: `yadm pull` plus the `ai_workstation` role.

## 2026-10-23: Backup and sync audit
- Audit done and decisions recorded in the private knowledge map (`~/sync/ai/WORKSTATION.md`, section Backups); details stay out of this public repo.
- Done: three new backup scripts in `~/bin` (aufner.org, Zotero, AI harness state), local steps tested; Ph.D. vault pushed to a private GitHub repo after a clean gitleaks scan; `.config/yadm/encrypt` extended.
- 2026-10-23 (later): new scripts scheduled in the nightly unit; Serena project memories added to the AI state backup; Claude Code IDE plugin in all three vaults; petersgasse.at feature branch pushed.
- pcloud reconnected and the yadm archive re-encrypted with the new secrets (84b0573). Open for Peter: reload each vault in Obsidian once.

## 2026-10-23: More MCP servers
- RIS Austria, EUR-Lex, YouTube transcripts, ÖBB and Thunderbird added to all three harness templates (plugin 1.5.0; ansible `laptops`). Open for Peter: install the Thunderbird add-on from `/opt/mcp/thunderbird-mcp/` and restrict its accounts.

## 2026-10-24: Travel memory, ~/bin incident, memory-graph snapshots
- MCP memory graph (`~/sync/ai/mcp-memory.jsonl`): new entities `Travel planning` (standing order), `Packing lists`, `Travel history`, persons `Peter Aufner`, `Julia`, `Solveig`, `Elenore`; pointer line "Travel" in `~/sync/ai/WORKSTATION.md`.
- Incident: `~/bin` vanished on schulpc 2026-10-23 13:35 (cause unknown); Syncthing folder stopped with "folder path missing", peers kept the files; the 2026-10-24 02:00 `daily-cloud-sync` ran no script but reported success (`ExecStart=-`). Restored from m11x via `rsync -a m11x:bin/ ~/bin/`; Syncthing folder rescanned and back.
- `~/bin/backup-ai-state.sh`: dated snapshots (keep 90, only on change, empty/invalid JSONL refused) of `mcp-memory.jsonl` and `WORKSTATION.md` in `/backup/ai-state/snapshots/`; restore steps in the script header and in WORKSTATION.md (Backups). Function unit-tested in the scratchpad; first real run 2026-10-24 wrote both snapshots.
- Open: find the cause of the `~/bin` loss; failure alerting for `daily-cloud-sync` (an OnFailure unit or a check that the scripts exist) so a silent no-op night is noticed; pcloud token still revoked (`rclone config reconnect pcloud:`).

## 2026-10-25: Music backup fix, music taste in memory
- Music to OneDrive failed nightly on `DDRKirby(ISQ)/~Monthlies 2012.03~` (remote folder had a literal leading `~`; rclone encodes LeftTilde as `～`). Fixed by `rclone moveto --onedrive-encoding <default minus LeftTilde>` to the encoded name; dry run clean, 321 intended deletions (2.1 GiB) pending. The real sync was blocked by the auto-mode classifier: next nightly run applies it, or Peter runs it manually.
- pcloud authenticates again but is extremely slow; the 2026-10-25 run hung for 5+ h in backup-code-alongside.sh (pcloud), delaying mail/aufner/zotero/ai-state. Open: add a time limit (`--max-duration` or `timeout`) to pcloud uploads (offered, not done).
- Peter's confirmed music taste (local ~/Music only, Rammstein excluded, bardcore as a style) stored on `Peter Aufner`; Lord Of The Lost and Chris Harms on `Julia`; concert check added to `Travel planning`.
- Done later 2026-10-25: `~/bin/lib/cloud-upload.sh` (parallel OneDrive + pcloud, pcloud time budget: sync_cloud 2 h, code-alongside 1 h, others 30 min, `SLOW_REMOTE_MAX_SECONDS`); all 7 upload scripts use it. Tested with a fake rclone (parallel run, budget skip, hard kill after budget + grace, failure propagation) and a real `backup-zotero.sh -n`. Files swapped in by `mv` because backup-code-alongside.sh was running.
- Open: the 2026-10-25 run is still stuck in the OLD backup-code-alongside pcloud upload (PID 2506239); stopping it was blocked by the auto-mode classifier, Peter has to `kill` it so the later scripts run. Zotero backup has never reached either cloud yet.

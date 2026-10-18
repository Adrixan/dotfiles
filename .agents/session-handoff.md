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

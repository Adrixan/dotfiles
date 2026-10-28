---
name: rc-roles
description: Start, stop, list and create Claude Code remote-control roles on schulpc (code, teaching, educator, research, phd, travel, greeter and custom roles) with the `rc` command. Use when Peter greets the Greeter session, asks which roles are running, wants a role started or stopped ("start teacher for 3 hours", "stop everything idle", "fresh code session"), or wants a new custom role.
---

# rc-roles

Each role is a `claude-remote-control@<role>` user unit serving one folder; its sessions appear in the
Claude app under the role's label. Only the greeter starts at boot. `rc` (in `~/.local/bin`) does all
the work; never call `systemctl` on these units directly, because `rc` adds the RAM, trust and
busy-session guards.

## Commands
- `rc ls`: state, sessions, minutes since the last session activity, memory, plugins, description.
- `rc up <role> [--ttl 3h] [--fresh] [--force]`: `--ttl` stops the role automatically; `--fresh` starts a
  new session instead of resuming the last one; `--force` skips the RAM guard (1 GB available).
- `rc down <role> [--force]` and `rc restart <role> [--force]`: refuse while a session was active in the
  last 15 minutes; `--force` ends those sessions.
- `rc new <name> --label "…" --plugins dev,research,travel --brief "…" [--description "…"] [--args "--spawn worktree"]`:
  creates `~/Obsidian/Adrixan/AI/Roles/<name>` with `AGENTS.md` (the brief) and plugin settings. The core
  plugin (GitHub, memory, fetch, Nextcloud, mail, docs) is always on.
- `rc rm <name> [--force]` removes a custom role (the folder stays); `rc logs <role> [lines]`.

## How to act
- On a greeting or "what's running": run `rc ls` and answer with a short menu: running roles first (label,
  sessions, last activity, memory), then the stopped roles in one line, then free RAM.
- Map Peter's words to role names: teacher, Lehrer → teaching; coding, dev → code; trip, Reise, travel
  planner → travel; Prof. Aufner, content → educator; deep research → research; Dissertation → phd.
- Never add `--force` on your own. When `rc` refuses (recent activity, low RAM), report why and ask.
- Before `rc new`, settle in one question: name, label, plugins (suggest based on the purpose: code →
  dev; literature, law → research; trips → travel) and a two to four sentence brief that becomes the
  role's `AGENTS.md`. Custom-role briefs must not contain secrets or personal data of students or family.
- After `rc up`, tell Peter the session label to open in the Claude app; it appears within about 30 s.
  A role stopped less than about 2 minutes ago starts with a delay (the unit retries).
- A folder that is not trusted yet cannot start: tell Peter to run `cd <folder> && claude` once in a
  terminal and accept the dialog. Do not edit `~/.claude.json` to grant trust.
- Stopping the role that hosts the current session ends this conversation; say so before doing it.

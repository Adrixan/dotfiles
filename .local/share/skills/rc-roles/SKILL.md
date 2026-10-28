---
name: rc-roles
description: Start, stop, list and create Claude Code remote-control roles on schulpc (code, teaching, educator, research, phd, travel, greeter, one role per trip, one role per code project, and custom roles) with the `rc` command. Use when Peter greets the Greeter session, asks which roles are running, wants a role started or stopped ("start teacher for 3 hours", "stop everything idle", "fresh code session"), wants to plan a trip or resume one ("plan Berlin", "back to Prague"), wants to work on or create a code project, or wants a new custom role.
---

# rc-roles

Each role is a `claude-remote-control@<role>` user unit serving one folder; its sessions appear in the
Claude app under the role's label. Only the greeter starts at boot. `rc` (in `~/.local/bin`) does all
the work; never call `systemctl` on these units directly, because `rc` adds the RAM, trust and
busy-session guards.

## Commands
- `rc ls`: state, sessions, minutes since the last session activity, memory, plugins, description.
- `rc up <role> [--ttl 3h] [--fresh] [--force]`: resumes the role's previous sessions by default (the relay
  allows that for about 4 hours after the stop; later a new session starts and reads
  `.agents/session-handoff.md`); `--ttl` stops the role automatically; `--fresh` starts a new session on
  purpose; `--force` skips the RAM guard (1 GB available). Pass on the resume line `rc up` prints.
- `rc down <role> [--force]` and `rc restart <role> [--force]`: refuse while a session was active in the
  last 15 minutes; `--force` ends those sessions.
- `rc new <name> --label "…" --plugins dev,research,travel --brief "…" [--description "…"] [--args "--spawn worktree"]`:
  creates `~/Obsidian/Adrixan/AI/Roles/<name>` with `AGENTS.md` (the brief) and plugin settings. The core
  plugin (GitHub, memory, fetch, Nextcloud, mail, docs) is always on.
- `rc rm <name> [--force]` removes a custom role (the folder stays); `rc logs <role> [lines]`.
- Trips, several in parallel: `rc trip <destination> [up options]` creates the role `trip-<slug>` on first
  use (folder `~/Obsidian/Adrixan/Travel/Trips/<slug>` with the trip brief, travel and research plugins)
  and starts or resumes it later; `rc trips` lists them. Each trip keeps `trip.md` and its handoff in its
  folder, so it can be restored after any pause.
- Code projects: `rc projects` lists every folder in `~/code` (git, trust, role state, last session);
  `rc code <project>` creates and starts the role `code-<project>` (nothing is written into the repo);
  `rc code --new <name>` creates `~/code/<name>` with a minimal `AGENTS.md` first. A git repository needs its
  own trust before it can run as a role; until then the general `code` role covers it.

## How to act
- On a greeting or "what's running": run `rc ls` and answer with a short menu: running roles first (label,
  sessions, last activity, memory), then the stopped roles in one line, then free RAM.
- Map Peter's words to role names, then check the name exists in the current `rc ls` (roles, trips and
  code projects come and go): teacher, Lehrer → teaching; coding, dev → code; trip, Reise, travel
  planner → travel; Prof. Aufner, content → educator; deep research → research; Dissertation → phd.
- Before `rc down` or `rc restart` of a role with sessions: find its session with `ListAgents` (the name
  starts with the role folder's name), send it with `SendMessage` and `notify_when_idle: true`: "The
  Greeter is stopping this role: update `.agents/session-handoff.md` (trajectory, intent, open decisions,
  next steps), then stop." Stop the role after the idle notice. If no session is listed, or the notice
  says it expired, stop anyway and say the handoff may be missing.
- Never add `--force` on your own. When `rc` refuses (recent activity, low RAM), report why and ask.
- Before `rc new`, settle in one question: name, label, plugins (suggest based on the purpose: code →
  dev; literature, law → research; trips → travel) and a two to four sentence brief that becomes the
  role's `AGENTS.md`. Custom-role briefs must not contain secrets or personal data of students or family.
- After `rc up`, tell Peter the session label to open in the Claude app; it appears within about 30 s.
  A role stopped less than about 2 minutes ago starts with a delay (the unit retries).
- A folder that is not trusted yet cannot start: tell Peter to run `cd <folder> && claude` once in a
  terminal and accept the dialog. Do not edit `~/.claude.json` to grant trust.
- Stopping the role that hosts the current session ends this conversation; say so before doing it.

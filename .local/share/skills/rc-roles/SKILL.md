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
- Code projects, any number in parallel: `rc code <project>` creates and starts the role `code-<project>`
  (session "Code: <project>"), served from the helper folder `~/code/.rc/<project>`. Only one server
  per folder is possible and a repository in `~/code` is untrusted on its own, but the helper folder is
  not a git repository, so it inherits the `~/code` trust; auto mode edits `~/code/<project>` from there
  (no trust or permission entries are written). Its `.claude/settings.json`, written by rc, holds only the
  SessionStart hook (`rc hook code-session`) that gives the session its project focus and, when it is
  new, a status turn. Each role resumes its own previous session like any role. `rc projects` lists
  the folders in `~/code`, most recently used first. `rc code --new <name>` creates `~/code/<name>` with a
  minimal `AGENTS.md` first. Client repositories (`.claude/settings.json` with MCP or connector denials
  from `claude-client-init`) are refused, because a session outside the repo would not load those
  denials: they need `rc code --own <project>`, a role in the repo folder itself, which needs the repo's
  own trust. A repo's `.claude/` settings and `.mcp.json` are not loaded in helper-folder sessions either.
  The general `code` role (`~/code`) stays for cross-project work; its sessions ask for a project.
- `rc menu`: running roles, stopped fixed and custom roles, trips, recent projects and free RAM in one
  listing (the Greeter's menu).
- Roles return after a reboot: `rc up` marks a role as wanted, `rc down`, `rc rm` and an expired `--ttl`
  unmark it (state in `~/.local/state/claude-rc/wanted/`). The Greeter's SessionStart hook
  (`rc hook greeter-start`) runs `rc restore` first, which starts every wanted role that is not running,
  and adds what it restarted or could not restart to the start message. A `--ttl` does not survive a
  reboot.

## How to act
- On a greeting or "what's running": run `rc ls` and answer with a short menu: running roles first (label,
  sessions, last activity, memory), then the stopped roles in one line, then free RAM. The Greeter
  follows the menu in its own `AGENTS.md` instead.
- Map Peter's words to role names, then check the name exists in the current `rc ls` (roles, trips and
  code projects come and go): teacher, Lehrer → teaching; coding, dev → `rc code <project>`; trip,
  Reise, travel planner → `rc trip <destination>` (the general travel role is not offered); Prof.
  Aufner, content → educator; deep research → research; Dissertation → phd.
- Teaching and Deep Research start at boot (Ansible `autostart`) and reattach their previous session
  when it stopped less than about 4 h earlier; the Greeter offers them only when they are stopped.
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

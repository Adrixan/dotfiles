---
name: rc-roles
description: Start, stop, list and create Claude Code remote-control roles on schulpc (code, teaching, educator, research, phd, greeter, one role per trip, one role per code project, and custom roles) with the `rc` command. Use when Peter asks which roles are running (on any host), wants a role started or stopped ("start teacher for 3 hours", "stop everything idle", "fresh code session"), wants to plan a trip or resume one ("plan Berlin", "back to Prague"), wants to work on or create a code project, wants a deep research on a topic ("research <topic>") or to resume one, or wants a new custom role.
---

# rc-roles

Each role is a `claude-remote-control@<role>` user unit serving one folder; its sessions appear in the
Claude app under the role's label. Only the greeter starts at boot. `rc` (in `~/.local/bin`) does all
the work; never call `systemctl` on these units directly, because `rc` adds the RAM, trust and
busy-session guards.

## Commands
- `rc ls [--running|--short]`: state, sessions, minutes since the last session activity, memory, plugins,
  description; `--running` one line per running role, `--short` plus the stopped roles and RAM.
- Hosts (Peter, 2026-11-10): `--on <host>` anywhere runs the command on that host over its SSH alias
  (`rc up teaching --on xps`, `rc ls --short --on agentbox`): schulpc, xps (= xps13), m11x (serves no
  roles), agentbox (as `travel`), edu-micro (as `educator`); `RC_HOSTS` in `rc.env` replaces the list. An
  unreachable host (xps asleep) gives a clear error and changes nothing there.
- Greeter slash commands: `rc slash <ls|start|stop|restart|logs|menu|h> "<arguments>"` backs `/ls`,
  `/start`, `/stop`, `/restart`, `/logs`, `/menu` and `/h` in the Greeter (grammar: `rc slash h`); its
  UserPromptExpansion hook `rc hook greeter-slash` shows the output without a model turn and hands only
  `HANDOFF`/`BRIEF` lines (sessions to message) to the model. `RC_GREETER_FAST=no` in `rc.env` hands every
  output to the model, for clients that do not show hook messages.
- `rc up <role> [--ttl 3h] [--fresh] [--force]`: resumes the role's previous sessions by default (the relay
  allows that for about 4 hours after the stop; later a new session starts and reads
  `.agents/session-handoff.md`); `--ttl` stops the role automatically; `--fresh` starts a new session on
  purpose; `--force` skips the RAM guard (1 GB available). Pass on the resume line `rc up` prints.
- `rc down <role> [--wait 10] [--now|--cancel]`: with sessions running it returns at once and a
  background unit `rc-stop-<role>` stops the role within seconds once every live session has run
  `rc handoff-done` and ended that turn. Fallback for a role with one session that does not signal: its
  `.agents/session-handoff.md` (for code project roles the project's, for the general Code role the
  projects its live sessions are on) is newer than the request, that turn has ended (the global Stop hook
  records turn ends) and the session has been quiet for 60 s. After `--wait` minutes (default 10) it stops
  anyway unless a session is still in a turn; a session in a turn gets until twice that (20 min), then the
  stop is forced.
  Without sessions, or with `--now`, it stops at once; `--cancel` drops a pending stop, and so do `rc up`
  and `rc restart` of that role. The role is no longer restored after a reboot once the stop is
  requested. `rc menu` and `rc ls` show pending stops. No idle notice is needed. `rc restart <role>`
  restarts at once (the sessions reattach).
- `rc handoff-done [--stop] [--file <path>]`: run by a role's session after writing its handoff. It refuses
  when no handoff was written in the last 30 min (`--file` names a handoff outside the usual places) and
  records the signal for this session; with a stop pending, the role stops seconds after the turn ends.
  Without a pending stop it changes nothing, unless `--stop` is given, which requests the stop itself:
  for a session Peter tells directly to stop. The signalling turn sends no push.
- `rc new <name> --label "…" --plugins dev,research --brief "…" [--description "…"] [--args "--spawn worktree"]`:
  creates `~/Obsidian/Adrixan/AI/Roles/<name>` with `AGENTS.md` (the brief) and plugin settings. The core
  plugin (GitHub, memory, fetch, Nextcloud, mail, docs) is always on. Not for projects: those use
  `rc project`.
- `rc rm <name>` stops and removes a custom role (the folder stays); `rc logs <role> [lines]`.
- Two workstations (schulpc primary, xps13 standby, 2026-11-04): custom role confs travel through the
  Syncthing folder `~/sync/ai/claude-rc` (every rc command exchanges them first; `rc sync-confs` does it
  now), `rc rm` removes a role on both. `RC_SHARED_EXCLUDE` in a machine's `rc.env` keeps roles local
  (`code-ptsd` on schulpc). A role runs on one machine at a time: `rc up` (also through `rc code`,
  `rc research`, `rc project`) refuses while the other workstation runs it and names the stop command
  (`rc down <role> --on <host>`); an unreachable peer only gives a note. `rc restore` skips the check.
  xps13 has workspace trust only for the folders Peter accepted there (`cd <folder> && claude` once).
- Trips, several in parallel: `rc trip <destination> [up options]` creates the role `trip-<slug>` on first
  use (folder `~/Obsidian/Adrixan/Travel/Trips/<slug>` with the trip brief and the research plugin)
  and starts or resumes it later; `rc trips` lists them. Each trip keeps `trip.md` and its handoff in its
  folder, so it can be restored after any pause. `--brief "<text>"` (or `--brief -` with the text on
  stdin) carries Peter's full request: rc appends it to the trip's `brief.md` and queues it, and the trip
  folder's start hook (`rc hook trip-session`, added by `rc trip`) hands it to the next new session as its
  first message. Always pass his whole wording, never only the destination. Since 2026-11-04 trip roles run on the agentbox
  (`RC_TRIP_HOST=agentbox` in schulpc's `~/.config/claude-rc/rc.env`): `rc trip`, `rc trips` and
  `rc up|down|restart|logs|rm trip-*` forward there over SSH, the same commands work as before, and the
  folder syncs back through Syncthing. Never start a trip role on schulpc while it runs there.
- Vault projects (claude.ai-style: instruction note, `Wissen/`, `Memory/`, `Artifacts/`, `Chats/`,
  `.agents/`), whose default home since 2026-11-03 is `~/Obsidian/Adrixan/AI/Claude.ai/Projects/` (Peter;
  layout and rules in `~/Obsidian/Adrixan/AI/Roles/projects/AGENTS.md`): `rc project <Name> [--plugins P]
  [--description "…"] [up options]` starts the role that serves `Projects/<Name>` (name case-insensitive,
  e.g. `educator` for Prof. Aufner), else creates the role `project-<slug>` (label "Project: <Name>",
  research plugin unless `--plugins` says otherwise); an unknown name creates the folder with that layout
  first. The folder inherits the trust of `Projects/` (accepted 2026-11-03). `rc project --list` lists the
  folders with role (`-` = no own role yet; the Projects role serves those) and last activity. Code stays
  in `~/code`, linked from the project's `Wissen/Code.md`.
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
- Deep research per topic, any number in parallel: `rc research "<topic>" [up options]` creates the role
  `research-<slug>` (session "Research: <topic>"), served from the hidden helper folder
  `~/Obsidian/Adrixan/Research/.rc/<slug>` (inherits the Research trust and its `AGENTS.md`), creates the
  job folder `Research/Reports/<date>-<slug>/` with a `report.md` stub (`status: running`) and starts at
  once: its start hook sends the topic to the new session with the `deep-research` skill. Topic roles stop
  themselves after 8 h (`--ttl 8h` unless another `--ttl` is given). `rc research <slug>` (or the role
  name) resumes an existing topic: the session reattaches within about 4 h, later a new session reads
  report, sources and handoff and replies with a status. `rc researches` lists the topics with report
  status; `rc research --index` rewrites `Research/index.md`. Results always land in the vault (rules in
  `Research/AGENTS.md`).
- `rc menu`: running roles (with pending stops), stopped fixed and custom roles, trips, research topics,
  vault projects, recent code projects and free RAM in one
  listing (`/menu` in the Greeter).
- Roles return after a reboot: `rc up` marks a role as wanted, `rc down`, `rc rm` and an expired `--ttl`
  unmark it (state in `~/.local/state/claude-rc/wanted/`). The Greeter's SessionStart hook
  (`rc hook greeter-start`) runs `rc restore` first, which starts every wanted role that is not running,
  and adds what it restarted or could not restart to the start message. A `--ttl` does not survive a
  reboot.

## Handing work to the right session (Peter, 2026-11-09)
- Every session switches to the expert session instead of doing another role's work: code and tool
  development (scripts beyond a quick lookup, a new tool, a repo) → `rc code <project>` or
  `rc code --new <name>`; a deep research → `rc research "<topic>"`; trip planning → `rc trip`; a vault
  project → `rc project`; educator content → `rc up educator` (runs on edu-micro). Not in a role session
  of the wrong kind, and not by asking Peter for permission prompts in a folder that is not made for it.
- Brief for a new or stopped session: add `--brief -` and pipe the context on stdin
  (`printf '%s\n' "$text" | rc code <project> --brief -`; `rc trip` and `rc research` take it too, max
  20000 characters). The role's start hook hands it over as the first message (`[handoff]`,
  `[trip-brief]`, or appended to the `[deep-research]` start). The brief holds: Peter's request verbatim,
  goal, what is known or decided (paths of reports, notes, files), constraints, and what to report back.
  No secrets; student and family data only where the receiving role is allowed to hold them.
- Running session: rc does not queue a brief (it says so); send it with `SendMessage` to the session
  found with `ListAgents`. Own repo roles (`rc code --own`) have no rc start hook either: SendMessage once
  the session is listed (about 30 s after `rc up`).
- Other machines: `rc trip` forwards to the agentbox (`RC_TRIP_HOST`), `rc up|down|restart|logs educator`
  to edu-micro (`RC_REMOTE_ROLES`), and any command takes `--on <host>`; a brief travels on stdin over SSH. `rc up` takes no brief, so the
  educator gets its context by SendMessage once its session is listed. `ListAgents` in a Remote Control
  session also lists the Remote Control sessions of Peter's account on the other machines (kind
  "Remote Control", label = role label, e.g. "Trip <destination>", "educator", "Travel Greeter"), and
  `SendMessage` with that name delivers there. Limits: no delivery or idle notice comes back from those
  sessions (`notify_when_idle` works only on this machine), a session in another permission mode may
  hold the message for Peter's approval, and an offline (stopped) session gets nothing, so start the
  role first and prefer `--brief` for new sessions. Plain terminal sessions on other machines are not
  listed. The receiver can answer with SendMessage to the `from` address (`bridge:session_…`; tested
  schulpc ↔ agentbox 2026-11-09), but do not wait for it: lasting results go to its files (handoff,
  report, trip.md).
- Afterwards tell Peter the session label to open and record the handoff in this session's own state
  (handoff, report or project `Memory/`).

## How to act
- On a greeting or "what's running": run `rc ls` and answer with a short menu: running roles first (label,
  sessions, last activity, memory), then the stopped roles in one line, then free RAM. The Greeter shows
  no menu since 2026-11-10: Peter types its slash commands (its own `AGENTS.md`).
- Map Peter's words to role names, then check the name exists in the current `rc ls` (roles, trips and
  code projects come and go): teacher, Lehrer → teaching; coding, dev → `rc code <project>`; trip,
  Reise, travel planner → `rc trip <destination>` (the general travel role is not offered); Prof.
  Aufner, content → educator; "research <topic>", deep research on a topic → `rc research "<topic>"`
  (general research chat without a topic → research); Dissertation → phd; "Projekt <Name>" or any name
  under VAULT PROJECTS in `rc menu` → `rc project <Name>`.
- Teaching and Deep Research start on request like the other roles (no boot start since 2026-11-03,
  Peter) and reattach their previous session when it stopped less than about 4 h earlier.
- Stopping a role with sessions: run `rc down <role>` first (it records the request time and starts the
  bounded wait), then find its sessions with `ListAgents` (the names start with the role folder's name)
  and send every one of them with `SendMessage`: "The Greeter is stopping this role: update
  `.agents/session-handoff.md` (trajectory, intent, open decisions, next steps) now, then run
  `rc handoff-done` and end the turn with one short line; the role stops seconds later." No
  `notify_when_idle`. If no session is listed, use `rc down <role> --now` and say the
  handoff may be missing. Peter saying "stop now" or "force" means `--now`.
- The RAM guard of `rc up` stays: never add `--force` to `rc up` on your own; report the refusal and ask.
- Before `rc new`, settle in one question: name, label, plugins (suggest based on the purpose: code →
  dev; literature, law → research; trips never get a custom role, they use `rc trip`) and a two to four sentence brief that becomes the
  role's `AGENTS.md`. Custom-role briefs must not contain secrets or personal data of students or family.
- After `rc up`, tell Peter the session label to open in the Claude app; it appears within about 30 s.
  A role stopped less than about 2 minutes ago starts with a delay (the unit retries).
- A folder that is not trusted yet cannot start: tell Peter to run `cd <folder> && claude` once in a
  terminal and accept the dialog. Do not edit `~/.claude.json` to grant trust.
- Stopping the role that hosts the current session ends this conversation; say so before doing it.

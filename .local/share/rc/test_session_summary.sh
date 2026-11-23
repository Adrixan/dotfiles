#!/bin/bash
# Sandbox checks for the start summary of rc sessions (Peter, 2026-11-23; no units started).
# Usage: ~/.local/share/rc/test_session_summary.sh <absolute scratch dir> (deleted and recreated)
set -u
SB="${1:?absolute sandbox dir}"; RC="$HOME/.local/bin/rc"; pass=0; fail=0
ok() { if eval "$2"; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi; }
rm -rf "$SB"; mkdir -p "$SB/.config/claude-rc" "$SB/.local/state/claude-rc/briefs" "$SB/.local/state/claude-rc/reboot-notes"
ST="$SB/.local/state/claude-rc"
conf() { printf '# Created by rc new\nRC_DIR="%s"\nRC_NAME="%s"\n' "$2" "$3" > "$SB/.config/claude-rc/$1.conf"; }
# hook <RC_DIR> <hook> <cse id|-> [source] [transcript]: the hook runs as a child of a process whose
# command line carries --session-id, as under `claude --sdk-url` (remote_session_id walks the parents)
hook() {
    local input; input="$(jq -nc --arg s "${4:-startup}" --arg t "${5:-}" '{source: $s, session_id: ("u-" + $id), transcript_path: $t}' --arg id "$3")"
    if [[ "$3" == - ]]; then  # `claude -p` (a probe) run inside a role session: the parent chain holds a cse id
        env -i HOME="$SB" PATH=/usr/bin:/bin RC_DIR="$1" bash -c 'exec -a claude bash -c '"'"'bash "$0" hook "$1" <<< "$2"; :'"'"' "$0" "$1" "$2" -p --session-id cse_P1' "$RC" "$2" "$input"
    else
        env -i HOME="$SB" PATH=/usr/bin:/bin RC_DIR="$1" bash -c 'bash "$0" hook "$1" <<< "$2"; :' "$RC" "$2" "$input" --session-id "$3"
    fi
}
msg() { jq -r '.hookSpecificOutput.initialUserMessage // empty' <<< "$1"; }
ctx() { jq -r '.hookSpecificOutput.additionalContext // empty' <<< "$1"; }
due_now() { mkdir -p "$ST/summary-due"; date +%s > "$ST/summary-due/$1"; }
age() { touch -d "-$2 seconds" "$1"; printf '%s\n' "$(( $(date +%s) - $2 ))" > "$1"; }

# --- a role with a handoff, no own start hook (BIMM-like vault project; global hook) ---
P="$SB/Obsidian/Adrixan/AI/Claude.ai/Projects/Bimm Like"; mkdir -p "$P/.agents" "$P/Memory"
conf bimm "$P" BIMM; echo "## 2026-11-15 done X" > "$P/.agents/session-handoff.md"; echo "m" > "$P/Memory/old.md"
out="$(hook "$P" session-start cse_A1)"
ok "handoff role: new session gets [session-summary]" '[[ "$(msg "$out")" == "[session-summary]"* && "$(msg "$out")" == *"Bimm Like/.agents/session-handoff.md"* ]]'
ok "summary asks for at most 5 lines and the four points" '[[ "$(msg "$out")" == *"at most 5 lines"*"done last"*"open"*"needs Peter"*"next step"* ]]'
ok "handoff wins over Memory/ notes" '[[ "$(msg "$out")" != *"Memory/old.md"* ]]'
ok "old hook name reboot-note does the same" '[[ "$(msg "$(hook "$P" reboot-note cse_A0)")" == "[session-summary]"* ]]'
ok "reattached session stays quiet (restart, restore)" '[[ -z "$(hook "$P" session-start cse_A1 resume)" ]]'
age "$ST/summary-seen/cse_A1" 120; due_now bimm
ok "reattached after rc up: summary once" '[[ "$(msg "$(hook "$P" session-start cse_A1 resume)")" == "[session-summary]"* ]]'
ok "then quiet again" '[[ -z "$(hook "$P" session-start cse_A1 resume)" ]]'
age "$ST/summary-seen/cse_A1" 3000; age "$ST/summary-due/bimm" 1500
ok "an rc up older than 20 min does not count" '[[ -z "$(hook "$P" session-start cse_A1 resume)" ]]'
ok "compaction never summarises" '[[ -z "$(hook "$P" session-start cse_A9 compact)" ]]'
ok "claude -p probe inside a role session: quiet" '[[ -z "$(hook "$P" session-start -)" ]]'
ok "folder without a role: quiet" '[[ -z "$(hook "$SB/elsewhere" session-start cse_A2)" ]]'
# reboot note: a reattached session gets the note only, a new one the summary and then the note
key="$(env -i HOME="$SB" PATH=/usr/bin:/bin bash -c "source <(sed -n '/^dir_key() {/,/^}/p' '$RC'); dir_key '$P'")"
date +%F > "$ST/reboot-notes/$key"
out="$(msg "$(hook "$P" session-start cse_A1 resume)")"
ok "restored after a reboot: reboot note only" '[[ "$out" == "[reboot]"* && "$out" != *"session-summary"* ]]'
date +%F > "$ST/reboot-notes/$key"
out="$(msg "$(hook "$P" session-start cse_A3)")"
ok "new session after a reboot: summary, then the note" '[[ "$out" == "[session-summary]"*"[reboot]"* ]]'

# --- sources other than a handoff ---
Q="$SB/Obsidian/Adrixan/AI/Claude.ai/Projects/Mem Only"; mkdir -p "$Q/Memory" "$Q/Chats"; conf project-mem-only "$Q" "Project: Mem Only"
echo a > "$Q/Memory/a.md"; sleep 1; echo b > "$Q/Memory/b.md"; echo c > "$Q/Chats/c.md"
out="$(msg "$(hook "$Q" session-start cse_B1)")"
ok "no handoff: newest Memory/ and Chats/ notes" '[[ "$out" == *"Memory/b.md"*"Chats/c.md"* && "$out" != *"Memory/a.md"* ]]'
T="$SB/Roles/tonly"; mkdir -p "$T"; conf tonly "$T" "T only"
tk="$SB/.claude/projects/$(sed 's/[^A-Za-z0-9]/-/g' <<< "$T")"; mkdir -p "$tk"
head -c 3000 /dev/zero | tr '\0' x > "$tk/old.jsonl"; touch -d '-1 hour' "$tk/old.jsonl"; head -c 3000 /dev/zero | tr '\0' x > "$tk/cur.jsonl"
out="$(msg "$(hook "$T" session-start cse_B2 startup "$tk/cur.jsonl")")"
ok "nothing but transcripts: the newest earlier one" '[[ "$out" == *"transcript ~/.claude/projects/"*"/old.jsonl"* && "$out" != *"cur.jsonl"* ]]'
F="$SB/Roles/fresh"; mkdir -p "$F"; echo "# brief" > "$F/AGENTS.md"; conf fresh "$F" Fresh
ok "fresh role: quiet" '[[ -z "$(hook "$F" session-start cse_B3)" ]]'
ok "the fresh session is recorded (a later reattach stays quiet)" '[[ -f "$ST/summary-seen/cse_B3" && -z "$(hook "$F" session-start cse_B3 resume)" ]]'

# --- the Greeters keep their own start ---
G="$SB/Obsidian/Adrixan/AI/Greeter"; mkdir -p "$G/.agents"; echo h > "$G/.agents/session-handoff.md"; conf greeter "$G" Greeter
TG="$SB/Obsidian/Adrixan/Travel/.greeter"; mkdir -p "$TG/.agents"; echo h > "$TG/.agents/session-handoff.md"; conf travel-greeter "$TG" "Travel Greeter"
ok "Greeter: no summary" '[[ -z "$(hook "$G" session-start cse_G1)" ]]'
ok "Travel Greeter: no summary" '[[ -z "$(hook "$TG" session-start cse_G2)" ]]'

# --- vault project with its own hook: queued brief first, then the summary; a job's brief wins ---
V="$SB/Obsidian/Adrixan/AI/Claude.ai/Projects/Vp"; mkdir -p "$V/.agents" "$V/.claude"; conf project-vp "$V" "Project: Vp"
echo "## state" > "$V/.agents/session-handoff.md"
printf '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"\\"$HOME/.local/bin/rc\\" hook project-session"}]}]}}\n' > "$V/.claude/settings.json"
ok "global hook leaves a project with its own hook alone" '[[ -z "$(hook "$V" session-start cse_V0)" ]]'
rm -f "$ST/summary-seen/cse_V0"
echo "Peter: do Y" > "$ST/briefs/project-vp"
out="$(msg "$(hook "$V" project-session cse_V1)")"
ok "brief first, then the summary" '[[ "$out" == "[project-brief] Vp"*"Peter: do Y"*"Then add a summary of the previous state of at most 5 lines"*"Vp/.agents/session-handoff.md"* ]]'
ok "project hook without a brief: summary" '[[ "$(msg "$(hook "$V" project-session cse_V2)")" == "[session-summary]"* ]]'
echo "Job: do Z" > "$ST/briefs/project-vp"; : > "$ST/briefs/project-vp.job"
out="$(hook "$V" project-session cse_V3)"
ok "job brief: the message is the brief alone" '[[ "$(msg "$out")" == "[project-brief] Vp"*"Job: do Z"* && "$(msg "$out")" != *"summary"* ]]'
ok "job brief: one context line on the earlier state" '[[ "$(ctx "$out")" == *"scheduled job, so its brief wins"*"at most one line"* ]]'
ok "job mark taken with the brief" '[[ ! -e "$ST/briefs/project-vp.job" && ! -e "$ST/briefs/project-vp" ]]'

# --- code project roles (helper folder) and the general Code role ---
mkdir -p "$SB/code/.rc/proj" "$SB/code/proj/.agents" "$SB/code/bare" "$SB/code/.rc/bare" "$SB/code/.agents"
conf code-proj "$SB/code/.rc/proj" "Code: proj"; conf code-bare "$SB/code/.rc/bare" "Code: bare"; conf code "$SB/code" Code
echo "## next: ship" > "$SB/code/proj/.agents/session-handoff.md"; echo "## cross-project log" > "$SB/code/.agents/session-handoff.md"
out="$(hook "$SB/code/.rc/proj" code-session cse_C1)"
ok "code project: summary from the project's handoff, with branch" '[[ "$(msg "$out")" == "[session-summary]"*"code/proj/.agents/session-handoff.md"*"branch and uncommitted changes"* ]]'
ok "code project: focus context kept" '[[ "$(ctx "$out")" == "Code session focused on the project proj"* ]]'
ok "code project reattached: quiet" '[[ -z "$(msg "$(hook "$SB/code/.rc/proj" code-session cse_C1 resume)")" ]]'
ok "code project without any state: the old [code-focus] status" '[[ "$(msg "$(hook "$SB/code/.rc/bare" code-session cse_C2)")" == "[code-focus] bare"* ]]'
echo "Peter: fix it" > "$ST/briefs/code-proj"
out="$(msg "$(hook "$SB/code/.rc/proj" code-session cse_C3)")"
ok "code brief first, then the summary" '[[ "$out" == "[handoff] proj"*"Peter: fix it"*"Then add a summary of the previous state"* ]]'
echo "Scan: fix CVE" > "$ST/briefs/code-proj"; : > "$ST/briefs/code-proj.job"
out="$(hook "$SB/code/.rc/proj" code-session cse_C4)"
ok "scan job brief: brief alone, summary as context" '[[ "$(msg "$out")" != *"summary"* && "$(ctx "$out")" == *"scheduled job"* ]]'
out="$(msg "$(hook "$SB/code" code-session cse_C5)")"
ok "general Code role: summary, then the project question" '[[ "$out" == "[session-summary]"*"code/.agents/session-handoff.md"*"ask which project"* && "$out" != *"wait for his request"* ]]'

# --- trips ---
TR="$SB/Obsidian/Adrixan/Travel/Trips/rome"; mkdir -p "$TR"; conf trip-rome "$TR" "Trip Rome"
echo "first request" > "$TR/brief.md"; echo "Rome, plan me" > "$ST/briefs/trip-rome"
out="$(msg "$(hook "$TR" trip-session cse_T1)")"
ok "new trip: the brief only (nothing to summarise yet)" '[[ "$out" == "[trip-brief]"* && "$out" != *"summary"* ]]'
echo "# Rome trip" > "$TR/trip.md"
out="$(msg "$(hook "$TR" trip-session cse_T2)")"
ok "trip with trip.md: summary" '[[ "$out" == "[session-summary]"*"rome/trip.md"* ]]'

# --- research topics ---
RS="$SB/Obsidian/Adrixan/Research/.rc/topic-x"; mkdir -p "$RS" "$SB/Obsidian/Adrixan/Research/Reports/2026-11-23-topic-x"
echo "Topic X" > "$RS/topic.txt"; echo "Reports/2026-11-23-topic-x" > "$RS/job"; conf research-topic-x "$RS" "Research: Topic X"
out="$(msg "$(hook "$RS" research-session cse_R1)")"
ok "new research topic: the research start only" '[[ "$out" == "[deep-research] Load the deep-research skill"* && "$out" != *"summary"* ]]'
echo "status: running" > "$SB/Obsidian/Adrixan/Research/Reports/2026-11-23-topic-x/report.md"
out="$(msg "$(hook "$RS" research-session cse_R2)")"
ok "later research session: summary with the report" '[[ "$out" == "[session-summary]"*"topic-x/report.md"* ]]'

# --- rc side: rc up marks, a restore does not; queue_brief marks job briefs ---
fn() { env -i HOME="$SB" PATH=/usr/bin:/bin "$@"; }
lib="die(){ echo \"die: \$*\"; exit 1; }; STATE_DIR='$ST'; BRIEFS_DIR='$ST/briefs'; SUMMARY_DUE='$ST/summary-due'; unit(){ echo u; }; systemctl(){ return 3; }; conf_get(){ echo x; }
source <(sed -n '/^mark_summary_due() {/,/^}/p; /^queue_brief() {/,/^}/p' '$RC')"
rm -rf "$ST/summary-due"
fn bash -c "$lib; mark_summary_due r1; RC_SUMMARY_MARK=no mark_summary_due r2"
ok "rc up marks the role, a restore does not" '[[ -f "$ST/summary-due/r1" && ! -e "$ST/summary-due/r2" ]]'
fn bash -c "$lib; BRIEF_SET=yes; BRIEF=b; queue_brief rp" >/dev/null
fn INVOCATION_ID=abc bash -c "$lib; BRIEF_SET=yes; BRIEF=b; queue_brief rj" >/dev/null
fn INVOCATION_ID=abc RC_DIR=/x bash -c "$lib; BRIEF_SET=yes; BRIEF=b; queue_brief rg" >/dev/null
fn RC_BRIEF_ORIGIN=job bash -c "$lib; BRIEF_SET=yes; BRIEF=b; queue_brief rx" >/dev/null
ok "brief from a shell or SSH: Peter's" '[[ -f "$ST/briefs/rp" && ! -e "$ST/briefs/rp.job" ]]'
ok "brief from a systemd job: marked" '[[ -f "$ST/briefs/rj.job" ]]'
ok "brief from a role session (unit with RC_DIR): Peter's" '[[ ! -e "$ST/briefs/rg.job" ]]'
ok "RC_BRIEF_ORIGIN=job marks it" '[[ -f "$ST/briefs/rx.job" ]]'
echo; echo "passed $pass, failed $fail"
[[ "$fail" -eq 0 ]]

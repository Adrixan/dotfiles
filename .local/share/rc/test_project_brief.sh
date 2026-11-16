#!/bin/bash
# Sandbox checks for rc project --brief and its start hook (no units started; 2026-11-16).
# Usage: ~/.local/share/rc/test_project_brief.sh <absolute scratch dir> (deleted and recreated)
set -u
SB="${1:?absolute sandbox dir}"; RC="$HOME/.local/bin/rc"; pass=0; fail=0
ok() { if eval "$2"; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi; }
rm -rf "$SB"; mkdir -p "$SB/.config/claude-rc" "$SB/.local/state/claude-rc/briefs" "$SB/.local/state/claude-rc/reboot-notes"
P="$SB/Obsidian/Adrixan/AI/Claude.ai/Projects/Test Proj"; mkdir -p "$P/.claude"
printf '# x\nRC_DIR="%s"\nRC_NAME="Project: Test Proj"\n' "$P" > "$SB/.config/claude-rc/project-test-proj.conf"
run() { env -i HOME="$SB" PATH=/usr/bin:/bin RC_DIR="$1" bash "$RC" hook "$2" < /dev/null; }
printf 'Line one\nLine "two"\n' > "$SB/.local/state/claude-rc/briefs/project-test-proj"
out="$(run "$P" project-session)"
ok "brief delivered as initialUserMessage" '[[ "$(jq -r .hookSpecificOutput.initialUserMessage <<< "$out")" == *"[project-brief] Test Proj"*"Line \"two\""* ]]'
ok "brief taken once" '[[ ! -e "$SB/.local/state/claude-rc/briefs/project-test-proj" ]]'
ok "second start silent" '[[ -z "$(run "$P" project-session)" ]]'
ok "other folders ignored" '[[ -z "$(run "$SB/elsewhere" project-session)" ]]'
printf 'x' > "$SB/.local/state/claude-rc/briefs/project-test-proj"
ok "folder without role ignored" '[[ -z "$(run "$SB/Obsidian/Adrixan/AI/Claude.ai/Projects/Other" project-session)" ]]'
rm -f "$SB/.local/state/claude-rc/briefs/project-test-proj"
# start_hook writes the hook once and keeps other settings
( export HOME="$SB"; source <(sed -n '/^start_hook() {/,/^}/p' "$RC"); echo '{"enabledPlugins":{"a":true}}' > "$P/.claude/settings.json"; start_hook "$P" project-session; start_hook "$P" project-session )
ok "start_hook adds the hook once" '[[ "$(jq "[.hooks.SessionStart[].hooks[] | select(.command|test(\"hook project-session\"))] | length" "$P/.claude/settings.json")" == 1 ]]'
ok "start_hook keeps settings" '[[ "$(jq .enabledPlugins.a "$P/.claude/settings.json")" == true ]]'
# reboot note: the project hook delivers it, the global hook skips folders with the project hook
key="$(env -i HOME="$SB" PATH=/usr/bin:/bin bash -c "source <(sed -n '/^dir_key() {/,/^}/p' '$RC'); dir_key '$P'")"
date +%F > "$SB/.local/state/claude-rc/reboot-notes/$key"
ok "global hook skips a project with its own hook" '[[ -z "$(run "$P" reboot-note)" && -e "$SB/.local/state/claude-rc/reboot-notes/$key" ]]'
out="$(run "$P" project-session)"
ok "project hook delivers the reboot note" '[[ -n "$(jq -r .hookSpecificOutput.initialUserMessage <<< "$out")" && ! -e "$SB/.local/state/claude-rc/reboot-notes/$key" ]]'
echo "{}" > "$P/.claude/settings.json"; date +%F > "$SB/.local/state/claude-rc/reboot-notes/$key"
ok "global hook still serves projects without the hook" '[[ -n "$(run "$P" reboot-note)" ]]'
# parse_brief in cmd_project: --brief text goes to BRIEF, the rest stays for rc up
r="$(env -i HOME="$SB" PATH=/usr/bin:/bin bash -c "die(){ echo \"die: \$*\"; exit 1; }; BRIEF_MAX=20000; source <(sed -n '/^parse_brief() {/,/^}/p' '$RC'); parse_brief --ttl 2h --brief hello --model x; echo \"\$BRIEF|\${UP_ARGS[*]}\"")"
ok "parse_brief splits brief and up args" '[[ "$r" == "hello|--ttl 2h --model x" ]]'
echo "passed $pass, failed $fail"; [[ $fail -eq 0 ]]

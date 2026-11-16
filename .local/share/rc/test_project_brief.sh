#!/bin/bash
# Sandbox checks for rc project --brief and its start hook (no units started; 2026-11-16).
# Usage: ~/.local/share/rc/test_project_brief.sh <absolute scratch dir> (deleted and recreated)
set -u
SB="${1:?absolute sandbox dir}"; RC="$HOME/.local/bin/rc"; pass=0; fail=0
project_has_hook_t() { grep -qsF 'bin/rc\" hook project-session' "$1/.claude/settings.json"; }
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

# --- project homes (2026-11-16): names that belong to another role, forwarded when remote ---
key() { env -i HOME="$SB" PATH=/usr/bin:/bin RC_REMOTE_ROLES="$2" RC_PROJECT_ROLES="${3:-}" bash -c "set -euo pipefail; die(){ echo \"die: \$*\"; exit 1; }; SHARED_CONF_DIR='$SB/sync/ai/claude-rc'; source <(sed -n '/^slugify() {/,/^}/p; /^PROJECT_ROLES_FILE=/p; /^name_key() /p; /^project_home_role() {/,/^}/p' '$RC'); project_home_role \"$1\""; }
mkdir -p "$SB/sync/ai/claude-rc"; printf '# comment\n\nProf. Aufner = educator\nGarden Plan=bimm\nBad = Not A Role\n' > "$SB/sync/ai/claude-rc/project-roles.list"
for n in "Prof. Aufner" "prof aufner" "PROF-AUFNER" "profaufner" "Prof.Aufner" "educator" "Educator"; do
    ok "home of '$n' is educator" '[[ "$(key "$n" "educator=educator@edu-micro")" == educator ]]'
done
ok "listed local home" '[[ "$(key "garden-plan" "")" == bimm ]]'
ok "unlisted project has no home" '[[ -z "$(key "BIMM" "educator=educator@edu-micro")" ]]'
ok "invalid role ignored" '[[ -z "$(key "Bad" "")" ]]'
ok "RC_PROJECT_ROLES pair" '[[ "$(key "Music Stuff" "" "music-stuff=project-music")" == project-music ]]'
# conf_value: quoted and unquoted confs (edu-micro writes KEY=value)
cv() { bash -c "source <(sed -n '/^conf_value() {/,/^}/p' '$RC'); conf_value \"\$1\" \"\$2\"" _ "$1" "$2"; }
printf 'RC_DIR="/a b/c"\nRC_NAME=educator\n' > "$SB/c.conf"
ok "conf_value quoted" '[[ "$(cv "$SB/c.conf" RC_DIR)" == "/a b/c" ]]'
ok "conf_value unquoted" '[[ "$(cv "$SB/c.conf" RC_NAME)" == educator ]]'
ok "conf_value missing key" '[[ -z "$(cv "$SB/c.conf" RC_ARGS)" ]]'
# full rc: rc project "<alias>" --brief - forwards over ssh (stub) and creates nothing here
mkdir -p "$SB/bin" "$SB/Obsidian/Adrixan/AI/Claude.ai/Projects/Prof. Aufner"
cat > "$SB/bin/ssh" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" > "$HOME/ssh.args"; cat > "$HOME/ssh.stdin"; echo "started educator with model m: open the session \"educator\""
STUB
chmod 700 "$SB/bin/ssh"
printf 'RC_REMOTE_ROLES="educator=educator@edu-micro"\nRC_SHARED_EXCLUDE=""\n' > "$SB/.config/claude-rc/rc.env"
before="$(ls "$SB/.config/claude-rc" | sort)"
for n in "Prof. Aufner" "prof-aufner" "educator"; do
    rm -f "$SB/ssh.args" "$SB/ssh.stdin"
    out="$(printf 'Peter says: hello\nline 2\n' | env -i HOME="$SB" PATH="$SB/bin:/usr/bin:/bin" bash "$RC" project "$n" --brief - --ttl 2h 2>&1)"
    ok "'$n' forwards rc up educator to edu-micro" '[[ "$out" == *"forwarding"* && "$(cat "$SB/ssh.args")" == *"educator@edu-micro"*".local/bin/rc up educator --ttl 2h --brief - " ]]'
    ok "'$n' brief travels on stdin" '[[ "$(cat "$SB/ssh.stdin")" == $'"'"'Peter says: hello\nline 2'"'"' ]]'
done
out="$(env -i HOME="$SB" PATH="$SB/bin:/usr/bin:/bin" bash "$RC" project "Prof Aufner" </dev/null 2>&1)"
ok "without a brief: plain rc up educator" '[[ "$(cat "$SB/ssh.args")" == *"rc up educator " ]]'
ok "no local role or folder created" '[[ "$(ls "$SB/.config/claude-rc" | sort)" == "$before" && ! -e "$SB/Obsidian/Adrixan/AI/Claude.ai/Projects/Prof Aufner" && ! -e "$SB/Obsidian/Adrixan/AI/Claude.ai/Projects/educator" ]]'
# rc up <role> --brief: queued only where an rc start hook hands it over
mkdir -p "$SB/stub"; printf '#!/bin/bash\nexit 3\n' > "$SB/stub/systemctl"; chmod 700 "$SB/stub/systemctl"
upb() { env -i HOME="$SB" PATH="$SB/stub:/usr/bin:/bin" bash -c "set -euo pipefail; die(){ echo \"die: \$*\"; exit 1; }
    CONF_DIR='$SB/.config/claude-rc'; STATE_DIR='$SB/.local/state/claude-rc'; BRIEFS_DIR=\"\$STATE_DIR/briefs\"; BRIEF_MAX=20000
    SLOTS_DIR='$SB/code/.rc'; RESEARCH_SLOTS='$SB/r/.rc'; TRIPS_DIR='$SB/t'; PROJECTS_HOME='$SB/Obsidian/Adrixan/AI/Claude.ai/Projects'
    unit(){ echo \"claude-remote-control@\$1.service\"; }
    source <(sed -n '/^conf_value() {/,/^}/p; /^conf_get() {/,/^}/p; /^parse_brief() {/,/^}/p; /^queue_brief() {/,/^}/p; /^start_hook() {/,/^}/p; /^up_brief() {/,/^}/p' '$RC')
    parse_brief --brief 'B'; up_brief \"\$1\" \"\$2\"" _ "$@"; }
E="$SB/Obsidian/Adrixan/AI/Claude.ai/Projects/Prof. Aufner"
printf 'RC_DIR=%s\nRC_NAME=educator\n' "$E" > "$SB/.config/claude-rc/educator.conf"
out="$(upb educator "$E")"
ok "rc up --brief queues for a project folder and adds its hook" '[[ -f "$SB/.local/state/claude-rc/briefs/educator" ]] && project_has_hook_t "$E"'
out="$(upb teaching "$SB/elsewhere")"
ok "rc up --brief for a role without rc start hook says SendMessage" '[[ "$out" == *"brief not queued"*"SendMessage"* && ! -f "$SB/.local/state/claude-rc/briefs/teaching" ]]'
# the educator start hook (unquoted conf) hands the brief over
out="$(env -i HOME="$SB" PATH=/usr/bin:/bin RC_DIR="$E" bash "$RC" hook project-session </dev/null)"
ok "project-session hook finds educator through its unquoted conf" '[[ "$(jq -r .hookSpecificOutput.initialUserMessage <<< "$out")" == *"[project-brief] Prof. Aufner"*B* ]]'
echo "passed $pass, failed $fail"; [[ $fail -eq 0 ]]

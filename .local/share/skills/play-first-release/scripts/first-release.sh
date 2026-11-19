#!/usr/bin/env bash
# first-release.sh <spec.env> [step ...]
# Drives the Play Console (logged-in Chromium with CDP) through the first release of one paid app.
# Steps (default: all, in this order):
#   create content rating audience safety settings listing price countries release check submit
# Env: DRY=1 stops the rating step before saving (review the answers), PLAY_CONFIG overrides the config path.
set -euo pipefail
S=$(cd "$(dirname "$0")" && pwd)
CONFIG=${PLAY_CONFIG:-$HOME/sync/ai/play-console/config.env}
[ -r "$CONFIG" ] || { echo "missing config $CONFIG" >&2; exit 2; }
# shellcheck source=/dev/null
. "$CONFIG"
SPEC=${1:?usage: first-release.sh <spec.env> [step ...]}; shift
# shellcheck source=/dev/null
. "$SPEC"
export PLAY_CDP
WORK=${PLAY_WORK:-$PWD/.scratch/play-console}; mkdir -p "$WORK/assets/$CODE"
URLF="$WORK/$CODE.url"
DEV="https://play.google.com/console/u/0/developers/$PLAY_ACCOUNT_ID"

pw() { node "$S/pw.mjs" "$@"; }
q() { node "$S/q.mjs" "$@"; }
say() { printf '[%s] %s\n' "$CODE" "$*"; }
die() { say "STOP: $*"; exit 1; }
A() { [ -s "$URLF" ] || die "no app URL yet (run step create)"; cat "$URLF"; }
go() { pw goto "$(A)/$1" >/dev/null; sleep 5; }
next() { pw clicksel 'role=button[name="Next"] >> nth=-1' >/dev/null; sleep "${1:-4}"; }
save_last() { pw clicksel 'role=button[name="Save"] >> nth=-1' >/dev/null; sleep 4; }
saved() { pw eval 'document.body.innerText.match(/(Change saved|Your changes have been saved)/)?.[0] || "NOT SAVED"'; }
body() { pw eval "document.body.innerText"; }

curl -sf "$PLAY_CDP/json/version" >/dev/null || die "no browser on $PLAY_CDP (start Chromium, see SKILL.md)"

step_create() {
  if [ -s "$URLF" ]; then say "app exists: $(A)"; return; fi
  pw goto "$DEV/create-new-app" >/dev/null; sleep 5
  pw fillrole textbox "App name" "$NAME" >/dev/null
  pw fillrole textbox "App package name" "$PACKAGE" >/dev/null
  pw clicksel 'role=button[name^="Default language"]' >/dev/null; sleep 1
  pw clicksel "role=option[name=\"$LANG_LABEL\"]" >/dev/null 2>&1 || pw clicktext "$LANG_LABEL" >/dev/null
  pw click radio "$TYPE" >/dev/null
  pw click radio "Paid" >/dev/null
  pw clicksel 'role=checkbox[name^="Confirm app meets"]' >/dev/null
  pw clicksel 'role=checkbox[name^="Accept US export"]' >/dev/null
  pw click button "Check availability" >/dev/null; sleep 2
  body | grep -q "Package name available" || die "package $PACKAGE not available"
  [ "$(pw eval '[...document.querySelectorAll("input[type=checkbox]")].every(e=>e.checked)')" = true ] || die "declarations not ticked"
  pw snap 2>&1 | grep -q "Default language: $LANG_LABEL" || die "default language not $LANG_LABEL"
  pw click button "Create app" >/dev/null
  local u=""; for _ in $(seq 1 10); do sleep 4; u=$(pw url); [[ $u == *app-dashboard ]] && break; done
  [[ $u == *app-dashboard ]] || die "create failed ($u)"
  echo "${u%/app-dashboard}" > "$URLF"; say "created $(A)"
}

step_content() {
  go app-content/privacy-policy; pw fillrole textbox "Privacy policy URL" "$PRIVACY" >/dev/null; pw click button "Save" >/dev/null; sleep 3; say "privacy: $(saved)"
  go app-content/ads-declaration; pw click radio "No, my app does not contain ads" >/dev/null; pw click button "Save" >/dev/null; sleep 3; say "ads: $(saved)"
  go app-content/testing-credentials; pw click radio "No" >/dev/null; pw click button "Save" >/dev/null; sleep 3; say "sign-in: $(saved)"
  go app-content/ad-id-declaration; pw click radio "No" >/dev/null; pw click button "Save" >/dev/null; sleep 3; say "advertising ID: $(saved)"
  go app-content/government-apps; pw click radio "No" >/dev/null; pw click button "Save" >/dev/null; sleep 3; say "government: $(saved)"
  go app-content/finance; pw clicksel "role=checkbox[name=\"My app doesn't provide any financial features\"]" >/dev/null; next 3; save_last; say "financial: $(saved)"
  go app-content/health; pw clicksel 'role=checkbox[name="My app does not have any health features"]' >/dev/null; next 3; save_last; say "health: $(saved)"
  go app-content/trader-status; pw fillrole textbox "Terms of Service" "$TERMS" >/dev/null; pw click button "Save" >/dev/null; sleep 3; say "trader: $(saved)"
}

step_rating() {
  go app-content/content-rating-overview
  pw click button "Start questionnaire" >/dev/null 2>&1 || pw click button "Edit questionnaire" >/dev/null 2>&1 || true; sleep 5
  pw fillsel 'role=group[name="Email address"] >> input' "$PLAY_EMAIL" >/dev/null
  pw click radio "$IARC_CAT" >/dev/null
  pw clicksel 'role=checkbox[name^="I agree to the Terms of Use"]' >/dev/null
  next 5
  # Questions appear progressively: answer No, apply overrides, repeat until stable.
  local pass o re ans line changed
  for pass in 1 2 3 4 5 6; do
    node "$S/allno.mjs" >/dev/null
    while read -r line; do q set "${line%%:*}" No >/dev/null 2>&1 || true; done < <(q list | grep -vE '\[(Yes|No)\]' || true)
    changed=0
    while IFS= read -r o; do [ -z "$o" ] && continue; re=${o%=*}; ans=${o##*=}
      while read -r line; do
        echo "$line" | grep -qF "[$ans]" && continue
        q set "${line%%:*}" "$ans" >/dev/null; changed=1
      done < <(q list | grep -iE "^[0-9]+: .*($re)" || true)
    done <<< "${IARC_OVERRIDES:-}"
    [ $changed = 0 ] && [ -z "$(q list | grep -vE '\[[^]]+\]' || true)" ] && break
  done
  q list
  [ -n "${DRY:-}" ] && { say "DRY: questionnaire filled, not saved"; exit 0; }
  q list | grep -qvE '\[[^]]+\]' && die "unanswered questions left (see list)"
  pw click button "Save" >/dev/null; sleep 4
  next 6
  say "ratings: $(pw eval 'document.body.innerText.match(/(PEGI \d+|USK: [^\n]*|Everyone[^\n]*|Teen|Mature)/g)?.join(", ")')"
  save_last
  go app-content/overview
  [ "$(pw eval '/\nContent ratings\n[^\n]*\n(Why this impacts your app\n[^\n]*\n)?Start declaration/.test(document.body.innerText)')" = true ] && die "rating not saved"
  say "rating saved"
}

step_audience() {
  go app-content/target-audience-content
  local b t i
  IFS='|' read -ra bands <<< "$AGES"
  for b in "${bands[@]}"; do pw clicksel "role=checkbox[name=\"$b\"]" >/dev/null; done
  for i in $(seq 1 8); do
    t=$(pw eval 'document.body.innerText.split(/Step \d of \d, [^\n]*\n/).pop().slice(0,1500)')
    case "$t" in
      *"told us"*) break ;;
      *"I certify that this app"*) pw clicksel 'role=checkbox[name^="I certify that this app"]' >/dev/null ;;
      *"Teacher Approved program"*)
        if [ "${TEACHER:-no}" = yes ]; then pw click radio "Include my app in the Teacher Approved program" >/dev/null
        else pw click radio "Do not include my app in the Teacher Approved program" >/dev/null; fi ;;
      *"unintentionally appeal to children"*) pw click radio "No" >/dev/null ;;
    esac
    next 3
    pw clicksel 'role=dialog >> role=button[name="OK"]' >/dev/null 2>&1 && next 3 || true
  done
  t=$(pw eval 'document.body.innerText.split("told us")[1]?.split("If you save")[0].replace(/\n+/g," ")')
  [ "$t" = null ] && die "target audience: summary not reached"
  say "audience:$t"
  save_last; say "audience: $(saved)"
}

step_safety() {
  go app-content/data-privacy-security
  next 4
  q set 1 No >/dev/null
  q list | grep -q commitment && q set 2 Yes >/dev/null
  next 4
  say "data safety: $(pw eval 'document.body.innerText.split("Store listing preview")[1]?.split("Step 5")[0].replace(/\n+/g," ").slice(0,300)')"
  save_last
  go app-content/overview
  local open; open=$(pw eval '[...document.body.innerText.matchAll(/\n([^\n]+)\n[^\n]*\n(?:Why this impacts your app\n[^\n]*\n)?Start declaration/g)].map(m=>m[1]).join(", ")')
  [ "$open" = '""' ] && say "all declarations actioned" || die "declarations still open: $open"
}

step_settings() {
  go store-settings
  pw eval '(()=>{const b=[...document.querySelectorAll("button")].filter(b=>b.innerText.trim()==="Edit");b[0].click();return 1})()' >/dev/null; sleep 2
  pw clicksel 'role=button[name^="Category"]' >/dev/null; sleep 1
  pw click option "$CATEGORY" >/dev/null
  pw click button "Save" >/dev/null; sleep 3
  pw click button "Close" >/dev/null 2>&1 || true
  pw eval '(()=>{const b=[...document.querySelectorAll("button")].filter(b=>b.innerText.trim()==="Edit");b[1].click();return 1})()' >/dev/null; sleep 2
  local D='role=dialog[name="Store listing contact details"]'
  pw fillsel "$D >> role=group[name=\"Email address\"] >> input" "$PLAY_EMAIL" >/dev/null
  pw fillsel "$D >> role=group[name=\"Website\"] >> input" "$PLAY_WEBSITE" >/dev/null
  pw clicksel "$D >> role=button[name=\"Save\"]" >/dev/null; sleep 3
  pw snap 2>&1 | grep -E 'group "(Category|Email address|Website)": ' | tr -d '\n'; echo
}

# --- listing helpers ---
addasset() { # <slot label prefix> <file>: open the slot's asset panel, upload, select, add
  local grp=$1 f=$2 n ok="" i
  n=$(basename "$f")
  pw clicksel "[role=group]:has-text(\"$grp\") >> role=button[name=\"Add assets\"]" >/dev/null; sleep 2
  pw upload 'input[type=file]' "$f" >/dev/null
  for i in $(seq 1 30); do
    pw clicksel "[aria-label=\"Deselected asset $n\"]" >/dev/null 2>&1 || true
    [ "$(pw eval "document.querySelector('[aria-label=\"Selected asset $n\"]')?'sel':'no'")" = '"sel"' ] && { ok=1; break; }
    # a single-asset slot may already have taken it
    pw snap 2>&1 | grep -q "button \"Remove $n\"" && { ok=2; break; }
    sleep 2
  done
  [ -n "$ok" ] || die "could not select asset $n"
  [ "$ok" = 1 ] && pw click button "Add" >/dev/null
  sleep 2
  pw click button "Close side panel" >/dev/null 2>&1 || true
}
prep_assets() { local l=$1 s=${1%-*} k f
  cp "$META/$l/images/icon.png" "$WORK/assets/$CODE/$CODE-$s-icon.png"
  cp "$META/$l/images/featureGraphic.png" "$WORK/assets/$CODE/$CODE-$s-feature.png"
  for k in phone sevenInch tenInch; do for f in "$META/$l/images/${k}Screenshots/"*.png; do
    [ -e "$f" ] && cp "$f" "$WORK/assets/$CODE/$CODE-$s-$k-$(basename "$f")"; done; done; true; }
fill_texts() { local l=$1
  pw fillrole textbox "App name" "$(cat "$META/$l/title.txt")" >/dev/null
  pw fillrole textbox "Short description" "$(cat "$META/$l/short_description.txt")" >/dev/null
  pw fillrole textbox "Full description" "$(cat "$META/$l/full_description.txt")" >/dev/null; }
add_shots() { local s=$1 x=$2 pair k lab f
  pw click button "Show content: Tablet assets" >/dev/null 2>&1 || true
  for pair in "phone:Phone screenshots" "sevenInch:7-inch tablet screenshots" "tenInch:10-inch tablet screenshots"; do
    k=${pair%%:*}; lab=${pair#*:}
    for f in $(ls "$WORK/assets/$CODE/$CODE-$s-$k-"*.png 2>/dev/null | sort -V); do addasset "$lab$x" "$f"; done
  done; }

step_listing() {
  read -ra locs <<< "$LOCALES"
  local L1=${locs[0]} L2=${locs[1]:-} s1 s2 f g diff=0 k i
  s1=${L1%-*}
  prep_assets "$L1"; [ -n "$L2" ] && prep_assets "$L2"
  go store-listings
  pw click button "Create default store listing" >/dev/null 2>&1 || pw click button "Edit default store listing" >/dev/null
  sleep 5
  fill_texts "$L1"
  addasset "App icon *" "$WORK/assets/$CODE/$CODE-$s1-icon.png"
  addasset "Feature graphic *" "$WORK/assets/$CODE/$CODE-$s1-feature.png"
  add_shots "$s1" " *"
  say "listing $L1 filled"
  if [ -n "$L2" ]; then
    s2=${L2%-*}
    pw clicksel 'role=button[name^="Default – "]' >/dev/null; sleep 1
    pw click menuitem "Manage languages" >/dev/null; sleep 2
    pw clicksel "role=dialog >> role=checkbox[name=\"$L2_LABEL\"]" >/dev/null
    pw clicksel 'role=dialog >> role=button[name="Apply"]' >/dev/null; sleep 4
    fill_texts "$L2"
    if ! cmp -s "$WORK/assets/$CODE/$CODE-$s1-icon.png" "$WORK/assets/$CODE/$CODE-$s2-icon.png"; then
      pw click button "Remove $CODE-$s1-icon.png" >/dev/null; addasset "App icon Your" "$WORK/assets/$CODE/$CODE-$s2-icon.png"; fi
    if ! cmp -s "$WORK/assets/$CODE/$CODE-$s1-feature.png" "$WORK/assets/$CODE/$CODE-$s2-feature.png"; then
      pw click button "Remove $CODE-$s1-feature.png" >/dev/null; addasset "Feature graphic Your" "$WORK/assets/$CODE/$CODE-$s2-feature.png"; fi
    for f in "$WORK/assets/$CODE/$CODE-$s2-"{phone,sevenInch,tenInch}-*.png; do
      [ -e "$f" ] || continue; g=${f/-$s2-/-$s1-}; cmp -s "$f" "$g" || diff=1; done
    if [ $diff = 1 ]; then
      pw click button "Show content: Tablet assets" >/dev/null 2>&1 || true
      for k in phone sevenInch tenInch; do for i in $(seq 1 8); do pw click button "Remove $CODE-$s1-$k-$i.png" >/dev/null 2>&1 || true; done; done
      add_shots "$s2" ""
    fi
    say "listing $L2 filled (own screenshots: $diff)"
  fi
  for i in 1 2 3 4; do
    pw snap 2>&1 | grep -q 'tab "Step 2 of 2, Review" \[selected\]' && break
    next 4
  done
  pw click radio "Don't label assets" >/dev/null   # graphics rendered by repo scripts, screenshots from the app
  save_last
  # verify on a fresh load
  go store-listings/default/edit
  say "listing saved, field lengths $(pw eval '[...document.querySelectorAll("textarea, input")].filter(e=>e.offsetParent&&e.type!=="file").slice(0,3).map(e=>e.value.length).join("/")')"
}

step_price() {
  local rows setp_ EURO bad net c r
  rows() { pw eval '[...document.querySelectorAll("[role=row]")].map(r=>[...r.querySelectorAll("[role=gridcell]")].map(c=>c.innerText.trim().replace(/\s+/g," "))).filter(r=>r.length>=3).map(r=>r.slice(-3).join("|"))'; }
  setp_() { local n=$1; shift
    pw click button "Set pricing" >/dev/null; sleep 1
    for c in "$@"; do pw clicksel "role=checkbox[name=\"$c\"]" >/dev/null; done
    pw click button "Continue" >/dev/null; sleep 2
    pw fillrole textbox "New price in EUR" "$n" >/dev/null
    pw clicksel 'role=dialog >> role=button[name="Update"]' >/dev/null; sleep 2; }
  go paid-app
  # The Console's price is net of VAT: aim every EEA euro country at the gross PRICE.
  setp_ "$(python3 -c "print(f'{$PRICE/1.2:.2f}')")" "Select all rows"
  EURO="Austria Belgium Bulgaria Croatia Cyprus Estonia Finland France Germany Greece Iceland Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Portugal Slovakia Slovenia Spain"
  for r in 1 2 3; do
    bad=$(rows | python3 -c "
import json,sys,re
P=float('$PRICE'); euro='$EURO'.split()
for row in json.load(sys.stdin):
    c,p,t=row.split('|')
    if c in euro and p!=f'EUR {P:.2f}':
        rate=float(re.match(r'([\d.]+)%',t).group(1))/100
        cur=float(p.split()[1]); step=(0.01 if P>cur else -0.01)*($r-1)
        print(f'{round(P/(1+rate),2)+step:.2f}\t{c}')
")
    [ -z "$bad" ] && break
    while IFS=$'\t' read -r net c; do setp_ "$net" "$c"; done <<< "$bad"
  done
  [ -n "$bad" ] && die "could not reach EUR $PRICE in: $bad"
  say "prices: $(rows | python3 -c "
import json,sys
show='Austria Germany Czechia Denmark Hungary Liechtenstein Norway Poland Romania Sweden United Kingdom'.split(' ')
print('; '.join(r.split('|')[0]+' '+r.split('|')[1] for r in json.load(sys.stdin) if r.split('|')[0] in show+['United Kingdom']))")"
  pw click button "Save changes" >/dev/null; sleep 4
  body | grep -q "Your changes have been saved" || die "price not saved"
  say "price saved"
}

step_countries() {
  local L c st n
  go tracks/production
  pw click tab "Countries / regions" >/dev/null; sleep 2
  pw click button "Add countries / regions" >/dev/null 2>&1 || pw click button "Edit countries / regions" >/dev/null; sleep 4
  L="Austria Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Iceland Ireland Italy Latvia Liechtenstein Lithuania Luxembourg Malta Netherlands Norway Poland Portugal Romania Slovakia Slovenia Spain Sweden"
  local want=30; [ "${UK:-no}" = yes ] && { want=31; L="$L United_Kingdom"; }
  for _ in 1 2 3; do
    for c in $L; do
      c=${c//_/ }
      st=$(pw eval "document.querySelector('[role=checkbox][aria-label=\"$c\"]')?.getAttribute('aria-checked')")
      [ "$st" = '"true"' ] || pw force "role=checkbox[name=\"$c\"]" >/dev/null
    done
    n=$(pw eval '[...document.querySelectorAll("[role=checkbox][aria-checked=true]")].filter(e=>e.getAttribute("aria-label")!=="Select all rows").length')
    [ "$n" = "$want" ] && break
  done
  [ "$n" = "$want" ] || die "$n countries ticked, want $want"
  pw click button "Save" >/dev/null; sleep 4
  pw snap 2>&1 | grep -q "Targeted ($want)" || die "targeting not saved"
  say "countries: $want targeted"
}

step_release() {
  local notes="" l i
  go tracks/production
  pw click button "Create new release" >/dev/null; sleep 8
  pw upload 'input[type=file]' "$AAB" >/dev/null
  for i in $(seq 1 40); do sleep 5; body | grep -qF "$VC (1.0.0)" && break; done
  body | grep -qF "$VC (1.0.0)" || die "bundle $VC (1.0.0) not shown after upload"
  for l in $LOCALES; do notes+="<$l>"$'\n'"$(cat "$META/$l/changelogs/$VC.txt")"$'\n'"</$l>"$'\n'; done
  pw fillsel 'input[aria-label="Release name"]' "1.0.0" >/dev/null
  pw fillsel 'textarea[aria-label="Release notes"]' "${notes%$'\n'}" >/dev/null; sleep 1
  next 7
  pw clicksel 'text="Show more" >> nth=0' >/dev/null 2>&1 || true
  pw clicksel 'text="Show more" >> nth=0' >/dev/null 2>&1 || true
  local issues; issues=$(pw eval '(document.body.innerText.split("Errors, warnings and messages")[1]||"").split("Release delivery")[0].replace(/\n+/g," ")')
  say "release issues: $issues"
  echo "$issues" | grep -qE '[1-9][0-9]* Errors?' && die "release has errors (left as draft)"
  save_last
  pw clicksel 'role=dialog >> role=button[name="Not now"]' >/dev/null 2>&1 || true
  say "release saved"
}

step_check() {
  go app-dashboard
  pw click button "View tasks for Provide information about your app and set up your store listing" >/dev/null 2>&1 || true
  local open; open=$(pw eval '(()=>{const t=document.body.innerText.split("Provide information about your app and set up your store listing")[1];if(!t)return "done";const m=t.match(/(\d+) of (\d+) complete/);return m&&m[1]===m[2]?"done":(m?m[0]:"unknown")})()')
  say "setup: $open"
  [ "$open" = '"done"' ] || die "dashboard setup not complete: $open (if only the store listing is open: open the editor and Save once more by hand)"
}

step_submit() {
  go publishing
  local i; for i in 1 2 3 4 5; do pw click button "Next slide" >/dev/null 2>&1 || break; done
  say "pending: $(pw eval 'document.body.innerText.match(/(Start full rollout|Add \d+ countries[^\n]*|Submit \d+ changes for review|To send changes for review[^\n]*)/g)?.join("; ")')"
  body | grep -q "To send changes for review, complete the required steps" && die "Console says setup incomplete"
  pw clicksel 'role=button[name^="Submit "]' >/dev/null; sleep 3
  pw clicksel 'role=dialog >> role=button[name="Send changes for review"]' >/dev/null; sleep 6
  body | grep -q "Changes in review" || die "submission not confirmed"
  say "SUBMITTED for review"
}

ALL="create content rating audience safety settings listing price countries release check submit"
for st in ${*:-$ALL}; do say "== $st"; "step_$st"; done

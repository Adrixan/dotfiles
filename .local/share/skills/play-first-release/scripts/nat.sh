#!/usr/bin/env bash
# nat.sh <group index> <label>: click the native radio input of a visible questionnaire group
cd "$(dirname "$0")"; export PLAY_CDP=${PLAY_CDP:-http://127.0.0.1:9333}
node pw.mjs eval "(()=>{const g=[...document.querySelectorAll('[role=tabpanel] [role=radiogroup]')].filter(e=>e.getClientRects().length)[$1];const ins=[...g.querySelectorAll('input[type=radio]')];const lab=ins.map(i=>i.closest('material-radio').innerText.trim());const k=lab.indexOf('$2');ins[k].click();return ins[k].checked})()"

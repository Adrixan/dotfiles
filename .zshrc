source ~/.config/zsh/aliases
source ~/.config/zsh/env
source ~/.config/zsh/grml
[ -f ~/.config/zsh/update-reminder ] && source ~/.config/zsh/update-reminder
[ -f ~/.config/zsh/ws-sync-status ] && source ~/.config/zsh/ws-sync-status

# One file for the workstations and Termux: PATH entries only where the directory exists, $HOME instead
# of /home/Adrixan. Last in the loop ends up first: ~/.local/bin, then opencode, then herd-lite.
# Installers stay out of this file (opencode runs with --no-modify-path; the Antigravity CLI installer
# line is covered by ~/.local/bin here).
typeset -U path PATH
for _d in "$HOME/.config/herd-lite/bin" "$HOME/.opencode/bin" "$HOME/.local/bin"; do
  [[ -d $_d ]] && path=("$_d" $path)
done
unset _d
export PATH
[[ -d $HOME/.config/herd-lite/bin ]] && export PHP_INI_SCAN_DIR="$HOME/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"

# Termux: Android reports the host name "localhost"; name it so prompts tell the phone apart.
[[ -n ${TERMUX_VERSION:-} && $HOST == localhost ]] && HOST=termux

agy-termux() {
  hash -r
  agy-va39 "$@"
}

a-termux() {
  hash -r
  agy-va39 "$@"
}

# Ph.D. research stack (2026-09-02)
[ -f ~/.research_stack.env ] && . ~/.research_stack.env
[ -f "$HOME/.config/ai/env" ] && source "$HOME/.config/ai/env"

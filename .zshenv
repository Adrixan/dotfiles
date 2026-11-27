# Read by every zsh, also non-interactive ones (`ssh host cmd`, scripts run with zsh). sshd's compiled
# PATH (/usr/bin:/bin:/usr/sbin:/sbin) lacks /usr/local/bin (claude-code-update, update-system) and
# ~/.local/bin (yadm-sync-all, ws-sync, rc); /etc/profile adds them only to login shells.
typeset -U path PATH
# rustup (xps13 had this line in an untracked ~/.zshenv; zsh never reads ~/.profile)
[[ -r "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
path=("$HOME/.local/bin" /usr/local/bin(N/) $path)  # (N/): only if it exists (not in Termux)
export PATH
# Termux: Android denies hard links in app storage, so uv copies at once instead of warning
# "Failed to hardlink files" on every tool upgrade.
[[ -n ${TERMUX_VERSION:-} ]] && export UV_LINK_MODE=copy

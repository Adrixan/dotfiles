# Read by every zsh, also non-interactive ones (`ssh host cmd`, scripts run with zsh). sshd's compiled
# PATH (/usr/bin:/bin:/usr/sbin:/sbin) lacks /usr/local/bin (claude-code-update, update-system) and
# ~/.local/bin (yadm-sync-all, ws-sync, rc); /etc/profile adds them only to login shells.
typeset -U path PATH
path=("$HOME/.local/bin" /usr/local/bin(N/) $path)  # (N/): only if it exists (not in Termux)
export PATH

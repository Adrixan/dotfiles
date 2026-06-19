source ~/.config/zsh/aliases
source ~/.config/zsh/env
source ~/.config/zsh/grml

export PATH="$HOME/.local/bin:$PATH"

agy-termux() {
  hash -r
  agy-va39 "$@"
}

a-termux() {
  hash -r
  agy-va39 "$@"
}


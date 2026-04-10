#!/usr/bin/env sh
# aliases.sh — public aliases, sourced by .zshrc and .bashrc

alias editAliases='nvim ~/.config/shell/aliases.sh'
alias resource='source ~/.zshrc'

# ── Navigation ────────────────────────────────────────────────────────────────
alias cd='z'
alias cdi='zi'

# ── File listing ──────────────────────────────────────────────────────────────
alias ls="eza --icons=always"
alias la='eza --icons=always -a'
alias ll='eza --icons=always -la'
alias tree="eza --icons --tree"

# ── Core replacements ─────────────────────────────────────────────────────────
alias cat='bat'
alias vim='nvim'
alias vi='nvim'
alias grep='grep --color -n'
alias find='fd'
alias top='htop'
alias du='du -hd 1'
alias folderSize='du -hd 1'

# ── Git ───────────────────────────────────────────────────────────────────────
alias gs='git status --porcelain'
alias lg='lazygit'

# ── Docker ────────────────────────────────────────────────────────────────────
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias ld='lazydocker'

# ── Kubernetes ────────────────────────────────────────────────────────────────
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kl='kubectl logs -f'
alias kx='kubectl exec -it'
alias kns='kubectl config set-context --current --namespace'

# ── Node / JS ─────────────────────────────────────────────────────────────────
alias ni='pnpm install'
alias nr='pnpm run'
alias nrd='pnpm run dev'
alias nrb='pnpm run build'
alias nrt='pnpm run test'

# ── Python / uv ───────────────────────────────────────────────────────────────
alias py='python3'
alias uvr='uv run'
alias uvs='uv sync'

# ── Misc utils ────────────────────────────────────────────────────────────────
alias myip='curl -s ifconfig.me && echo'
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'
alias flush='dscacheutil -flushcache && killall -HUP mDNSResponder'
alias path='echo $PATH | tr ":" "\n"'
alias reload='exec zsh'

# ── Dotfiles ──────────────────────────────────────────────────────────────────
alias restow='stow --restow . --target="$HOME" --dir="$HOME/dotfiles"'

# ── Apps (macOS only) ─────────────────────────────────────────────────────────
if [ "$(uname)" = "Darwin" ]; then
  alias code='open -a "/Applications/Visual Studio Code.app"'
  alias firefox='open -a "/Applications/Firefox.app"'
  alias zen='open -a "/Applications/Zen.app"'
fi
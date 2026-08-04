# ── Oh-My-Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(
  git
  sudo
  kubectl
  docker
  zsh-256color
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Guarded — install.sh's Shell section is skippable.
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# ── Shell modules ─────────────────────────────────────────────────────────────
source ~/.config/shell/init-apps.sh
source ~/.config/shell/aliases.sh

[ -f ~/.config/shell/private.sh ] && source ~/.config/shell/private.sh
[ -f ~/.config/shell/vibe.sh ]    && source ~/.config/shell/vibe.sh

# ── Completions ───────────────────────────────────────────────────────────────
fpath+=~/.zfunc
autoload -Uz compinit && compinit

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE=~/.shared_history
HISTSIZE=100000
SAVEHIST=100000
setopt hist_ignore_dups
setopt hist_ignore_space
setopt append_history
setopt extended_history

# ── Prompt: Starship ──────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Banner (interactive login shells only) ────────────────────────────────────
[[ -o interactive ]] && source ~/.config/shell/banner.sh

# ── Zoxide (must be last — it warns if anything initialises after it) ─────────
eval "$(zoxide init zsh)"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ── Shell modules ─────────────────────────────────────────────────────────────
source ~/.config/shell/init-apps.sh
source ~/.config/shell/aliases.sh

[ -f ~/.config/shell/private.sh ] && source ~/.config/shell/private.sh
[ -f ~/.config/shell/vibe.sh ]    && source ~/.config/shell/vibe.sh

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE=~/.shared_history
HISTSIZE=100000
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend

# ── Prompt: Starship ──────────────────────────────────────────────────────────
eval "$(starship init bash)"

# ── Banner ────────────────────────────────────────────────────────────────────
source ~/.config/shell/banner.sh

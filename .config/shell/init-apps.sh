#!/usr/bin/env sh
# init-apps.sh — PATH setup and tool initialization
# Sourced by both .zshrc and .bashrc

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# PATH additions
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/.lmstudio/bin"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Environment
export EDITOR=nvim
export LANG=en_US.UTF-8

# Postgres
export PGDATA="$HOME/postgres_data"
export PGHOST="/tmp"
export PGPORT="5432"

# Nix
[ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ] && \
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'

# Google Cloud SDK
[ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ] && \
  . "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"

# opam
[ -r "$HOME/.opam/opam-init/init.zsh" ] && \
  source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2>&1

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Shell-specific tool initialization
if [ -n "$ZSH_VERSION" ]; then
  eval "$(fzf --zsh)"
  eval "$(zoxide init zsh)"
  eval "$(direnv hook zsh)"
  [ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ] && \
    . "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"
elif [ -n "$BASH_VERSION" ]; then
  eval "$(fzf --bash)"
  eval "$(zoxide init bash)"
  eval "$(direnv hook bash)"
fi

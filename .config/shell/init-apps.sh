#!/usr/bin/env sh
# init-apps.sh — PATH setup and tool initialization
# Sourced by both .zshrc and .bashrc

# ── Homebrew ──────────────────────────────────────────────────────────────────
# Apple Silicon: /opt/homebrew  |  Intel Mac: /usr/local  |  Linux: /home/linuxbrew
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ── PATH ──────────────────────────────────────────────────────────────────────
# User-local binaries (highest priority — prepend)
[ -d "$HOME/.local/bin" ]                    && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.bun/bin" ]                      && export PATH="$HOME/.bun/bin:$PATH"
[ -d "$HOME/.antigravity/antigravity/bin" ]  && export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# Language runtimes (append — lower priority than user tools)
[ -d /usr/local/go/bin ]                     && export PATH="$PATH:/usr/local/go/bin"
[ -d "$HOME/.lmstudio/bin" ]                 && export PATH="$PATH:$HOME/.lmstudio/bin"

# ── Bun ───────────────────────────────────────────────────────────────────────
if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
fi

# ── Environment ───────────────────────────────────────────────────────────────
export EDITOR=nvim
export LANG=en_US.UTF-8

# ── Postgres (only if installed) ──────────────────────────────────────────────
if command -v psql > /dev/null 2>&1; then
  export PGDATA="$HOME/postgres_data"
  export PGHOST="/tmp"
  export PGPORT="5432"
fi

# ── Nix ───────────────────────────────────────────────────────────────────────
[ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ] && \
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'

# ── Google Cloud SDK (only if installed) ──────────────────────────────────────
if [ -d "$HOME/Downloads/google-cloud-sdk" ]; then
  [ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ] && \
    . "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"
fi

# ── OCaml / opam ──────────────────────────────────────────────────────────────
[ -r "$HOME/.opam/opam-init/init.zsh" ] && \
  source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2>&1

# ── Shell-specific tool initialization ────────────────────────────────────────
if [ -n "$ZSH_VERSION" ]; then
  command -v direnv > /dev/null 2>&1 && eval "$(direnv hook zsh)"
  command -v fzf    > /dev/null 2>&1 && eval "$(fzf --zsh)"
  [ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ] && \
    . "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"
elif [ -n "$BASH_VERSION" ]; then
  command -v direnv > /dev/null 2>&1 && eval "$(direnv hook bash)"
  command -v fzf    > /dev/null 2>&1 && eval "$(fzf --bash)"
  command -v zoxide > /dev/null 2>&1 && eval "$(zoxide init bash)"
fi

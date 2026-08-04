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
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.bun/bin" ]   && export PATH="$HOME/.bun/bin:$PATH"

# Language runtimes (append — lower priority than user tools)
[ -d /usr/local/go/bin ]  && export PATH="$PATH:/usr/local/go/bin"

# ── Bun ───────────────────────────────────────────────────────────────────────
if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
fi

# ── Environment ───────────────────────────────────────────────────────────────
export EDITOR=nvim
export LANG=en_US.UTF-8

# ── Nix ───────────────────────────────────────────────────────────────────────
[ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ] && \
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'

# ── Shell-specific tool initialization ────────────────────────────────────────
if [ -n "$ZSH_VERSION" ]; then
  command -v direnv > /dev/null 2>&1 && eval "$(direnv hook zsh)"
  command -v fzf    > /dev/null 2>&1 && eval "$(fzf --zsh)"
elif [ -n "$BASH_VERSION" ]; then
  command -v direnv > /dev/null 2>&1 && eval "$(direnv hook bash)"
  command -v fzf    > /dev/null 2>&1 && eval "$(fzf --bash)"
  command -v zoxide > /dev/null 2>&1 && eval "$(zoxide init bash)"
fi

# ── pnpm ──────────────────────────────────────────────────────────────────────
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ── nvm ───────────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \
  . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

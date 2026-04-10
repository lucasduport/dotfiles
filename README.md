# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html).

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/lucasduport/dotfiles/main/install.sh | bash
```

> Clones this repo to `~/dotfiles`, installs Homebrew, stows all configs, then walks you through each tool group. Run with `--all` to skip prompts.

## Structure

```
dotfiles/
├── .aerospace.toml          # AeroSpace tiling window manager
├── .bashrc                  # Bash (delegates to .config/shell/)
├── .zshrc                   # Zsh (delegates to .config/shell/)
├── .gitconfig               # Git global config
├── .vimrc                   # Vim config
├── .stow-local-ignore       # Files stow should not symlink
├── .config/
│   ├── shell/
│   │   ├── init-apps.sh     # PATH, evals (brew, fzf, zoxide, direnv, gcloud…)
│   │   ├── aliases.sh       # Public aliases
│   │   ├── banner.sh        # Terminal startup (fastfetch)
│   │   ├── private.sh       # Private aliases — gitignored, create manually
│   │   └── vibe.sh          # Vibe coding setup — gitignored, create manually
│   ├── starship.toml        # Starship prompt
│   ├── fastfetch/
│   │   ├── config.jsonc     # Fastfetch layout
│   │   └── logo.png         # Terminal banner logo
│   ├── nvim/                # Neovim config
│   ├── kitty/               # Kitty terminal
│   └── nix/                 # Nix config
```

## Install on a new machine

The curl command above handles everything. Alternatively:

The script installs Homebrew, all CLI tools, Mac apps (casks), fonts, stows dotfiles,
and prints a full version summary at the end. It is idempotent — safe to re-run.

<details>
<summary>Manual steps if you prefer</summary>

```sh
# Stow
stow . --target="$HOME"

# Core tools
brew install stow starship fastfetch zoxide fzf direnv eza bat \
  zsh-autosuggestions zsh-syntax-highlighting neovim git-delta lazygit \
  ripgrep fd jq yq tig gh tmux

# Create private files (never tracked by git)
touch ~/.config/shell/private.sh   # your private aliases
touch ~/.config/shell/vibe.sh      # AI keys, Claude Code config
```

</details>

## Private files

Two files are gitignored and must be created manually on each machine:

**`~/.config/shell/private.sh`** — private aliases, SSH shortcuts, work tooling

**`~/.config/shell/vibe.sh`** — vibe coding setup:
```sh
export ANTHROPIC_API_KEY=""
export CLAUDE_MODEL="claude-sonnet-4-6"
alias cc='claude'
```

## AeroSpace

Bindings use `cmd-*`. To avoid conflicts with app shortcuts, layout commands (tiles, accordion) live in **service mode** (`cmd-shift-;`).

| Binding | Action |
|---|---|
| `cmd-arrows` | Focus window |
| `cmd-shift-arrows` | Move window |
| `cmd-1..0` | Switch workspace |
| `cmd-shift-1..0` | Move window to workspace |
| `cmd-shift-space` | Toggle float/tile |
| `cmd-shift-f` | Native fullscreen |
| `cmd-tab` | Workspace back/forth |
| `cmd-shift-;` | Service mode |

**Service mode** (`cmd-shift-;` → key → auto-exits):

| Key | Action |
|---|---|
| `e` | Layout tiles |
| `s` | Layout accordion |
| `f` | Toggle float |
| `r` | Flatten/reset tree |
| `h/j/k/l` | Join with neighbor |
| `esc` | Reload config + exit |

## Fastfetch

Logo is tracked in the repo (`logo.png`) and renders inline in iTerm2 automatically.
For other terminals change `"type"` in `config.jsonc` to `"sixel"`, `"kitty"`, or `"chafa"`.

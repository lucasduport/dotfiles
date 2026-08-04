# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html).

## Install

```sh
git clone https://github.com/lucasduport/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh          # or --all to skip prompts
```

> Installs Homebrew, stows all configs, then walks you through each tool group.
> It is idempotent — safe to re-run.

Don't pipe the script from `curl` into `bash`. The installer prompts before each
section, and under a pipe stdin is the script itself, so the prompts would eat
the remaining lines of the script.

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
│   │   ├── init-apps.sh     # PATH, evals (brew, fzf, zoxide, direnv…)
│   │   ├── aliases.sh       # Public aliases
│   │   ├── banner.sh        # Terminal startup (fastfetch)
│   │   ├── private.sh       # Private aliases — gitignored, create manually
│   │   └── vibe.sh          # API keys / tooling env — gitignored, create manually
│   ├── starship.toml        # Starship prompt
│   ├── fastfetch/
│   │   ├── config.jsonc     # Fastfetch layout
│   │   └── logo.png         # Terminal banner logo
│   ├── git/hooks/           # Global gitleaks pre-commit hook
│   └── nix/                 # Nix config
```

Neovim is not tracked here — `install.sh` clones the
[NvChad starter](https://github.com/NvChad/starter) into `~/.config/nvim`
directly after installing Neovim.

## Stow and `--no-folding`

Always stow with `--no-folding` (the `restow` alias and `install.sh` both do):

```sh
stow --no-folding --restow . --target="$HOME" --dir="$HOME/dotfiles"
```

Without it, stow collapses `~/.config` into a **single symlink into this repo**.
Every application that writes to `~/.config` — gcloud, gh, zed, uv — then writes
its credentials straight into a public git working tree. With `--no-folding`,
`~/.config` stays a real directory and only tracked files are symlinked.

`.gitignore` enforces the same rule from the other side: everything under
`.config/` is denied by default and tracked paths are allowlisted, so a new
application dropping a token there can never become a commit candidate.

## Private files

These are gitignored and must be created manually on each machine:

**`~/.config/shell/private.sh`** — private aliases, SSH shortcuts, work tooling

**`~/.config/shell/vibe.sh`** — API keys and tooling env vars

**`~/.gitconfig.local`** — per-machine git identity (email, signing key).

**Work machines only** — internal package registry configuration, deliberately
kept out of this public repo:
`~/.config/uv/uv.toml`, `~/.config/pip/pip.conf`, `~/.config/pnpm/rc`.

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

Logo is tracked in the repo (`logo.png`). `"type"` is set to `"kitty"` in
`config.jsonc` — that's the Kitty graphics protocol, which Ghostty also
implements, so the logo renders inline in both. On a terminal without it, switch
to `"sixel"`, `"iterm"`, or `"chafa"`.

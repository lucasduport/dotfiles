#!/usr/bin/env bash
# install.sh — New Mac setup script
# Run:        bash install.sh          (interactive — pick what to install)
#             bash install.sh --all    (install everything, no prompts)

set -uo pipefail

# ── Flags ─────────────────────────────────────────────────────────────────────
AUTO_YES=false
[[ "${1:-}" == "--all" || "${1:-}" == "-y" ]] && AUTO_YES=true

# ── Colors ────────────────────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
WHITE="\033[37m"
BG_BLUE="\033[44m"
BG_MAGENTA="\033[45m"

# ── Helpers ───────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "${BOLD}${BG_BLUE}${WHITE}                                                    ${RESET}"
  echo -e "${BOLD}${BG_BLUE}${WHITE}         Lucas's Mac Setup — $(date +"%Y-%m-%d")           ${RESET}"
  echo -e "${BOLD}${BG_BLUE}${WHITE}                                                    ${RESET}"
  echo ""
}

section() {
  echo ""
  echo -e "${BOLD}${BG_MAGENTA}${WHITE}  $1  ${RESET}"
  echo -e "${DIM}──────────────────────────────────────────${RESET}"
}

log_step()  { echo -e "  ${CYAN}→${RESET} $1"; }
log_ok()    { echo -e "  ${GREEN}✓${RESET} ${BOLD}${1}${RESET}  ${DIM}${2}${RESET}"; }
log_skip()  { echo -e "  ${YELLOW}↩${RESET} ${BOLD}${1}${RESET}  ${DIM}already installed — ${2}${RESET}"; }
log_error() { echo -e "  ${RED}✗${RESET} $1"; }
log_fail()  { echo -e "  ${RED}✗ FAILED${RESET} ${BOLD}${1}${RESET}  ${DIM}${2}${RESET}"; }

FAILED=()  # tracks packages that failed to install

# Returns 0 (yes) or 1 (no). Skips prompt when --all is set.
ask() {
  local label="$1" ans=""
  if $AUTO_YES; then return 0; fi
  printf "\n  ${BOLD}Install %s?${RESET} [Y/n] " "$label"
  # Not stdin: under `curl | bash` that is the script itself.
  read -r ans < /dev/tty
  [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

# Without a terminal every prompt fails and silently skips its section.
if ! $AUTO_YES && ! { [[ -e /dev/tty ]] && : < /dev/tty; } 2>/dev/null; then
  log_error "No terminal available for prompts. Re-run with --all for a non-interactive install."
  exit 1
fi

# Homebrew 6 refuses casks from untrusted third-party taps.
brew_tap() {
  local tap="$1"
  if brew tap | grep -qx "$tap"; then
    log_skip "tap $tap" "already tapped"
  else
    log_step "Tapping ${tap}…"
    if brew tap "$tap" --quiet &>/dev/null; then
      log_ok "tap $tap" "tapped"
    else
      log_fail "tap $tap" "brew tap failed"
      FAILED+=("tap $tap")
      return
    fi
  fi
  brew trust --tap "$tap" &>/dev/null || true
}

brew_install() {
  local pkg="$1" label="${2:-$1}" out
  if brew list --formula "$pkg" &>/dev/null; then
    log_skip "$label" "$(brew info --json "$pkg" 2>/dev/null | jq -r '.[0].versions.stable' 2>/dev/null || echo "installed")"
  else
    log_step "Installing ${label}…"
    if out=$(brew install "$pkg" --quiet 2>&1); then
      log_ok "$label" "$(brew info --json "$pkg" 2>/dev/null | jq -r '.[0].versions.stable' 2>/dev/null || echo "✓")"
    else
      echo "$out" >&2
      log_fail "$label" "brew install $pkg failed — skipping"
      FAILED+=("$label")
    fi
  fi
}

brew_cask_install() {
  local pkg="$1" label="${2:-$1}" out
  if brew list --cask "$pkg" &>/dev/null; then
    log_skip "$label" "$(brew info --cask "$pkg" 2>/dev/null | head -1 | awk '{print $NF}' || echo "installed")"
  else
    log_step "Installing ${label} (cask)…"
    if out=$(brew install --cask "$pkg" --quiet 2>&1); then
      log_ok "$label" "installed"
    else
      echo "$out" >&2
      log_fail "$label" "brew install --cask $pkg failed — skipping"
      FAILED+=("$label")
    fi
  fi
}

# ── Entry ─────────────────────────────────────────────────────────────────────
print_banner

# ── Clone dotfiles if not present (curl | bash scenario) ──────────────────────
DOTFILES_DIR="$HOME/dotfiles"
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  section "00  Dotfiles"
  if ! command -v git &>/dev/null; then
    log_step "Installing Xcode Command Line Tools (needed for git)…"
    xcode-select --install 2>/dev/null || true
    log_ok "Xcode CLT" "installed"
  fi
  log_step "Cloning dotfiles to $DOTFILES_DIR…"
  git clone https://github.com/lucasduport/dotfiles.git "$DOTFILES_DIR"
  log_ok "Dotfiles" "cloned to $DOTFILES_DIR"
fi

if ! $AUTO_YES; then
  echo -e "  ${DIM}You will be asked before each section. Press Enter to accept, n to skip.${RESET}"
  echo -e "  ${DIM}Run with ${RESET}${BOLD}--all${RESET}${DIM} to skip all prompts.${RESET}"
fi

# ─────────────────────────────────────────────────────────────────────────────
section "01  Homebrew"   # always runs — everything else depends on it
# ─────────────────────────────────────────────────────────────────────────────
if command -v brew &>/dev/null; then
  log_skip "Homebrew" "$(brew --version | head -1)"
else
  log_step "Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  log_ok "Homebrew" "$(brew --version | head -1)"
fi
log_step "Updating Homebrew…"
brew update --quiet
echo -e "  ${GREEN}✓${RESET} Homebrew up to date"

# ─────────────────────────────────────────────────────────────────────────────
section "02  Dotfiles"   # stow early so configs are in place for later tools
# ─────────────────────────────────────────────────────────────────────────────
brew_install "stow" "GNU Stow"
log_step "Stowing dotfiles from ${DOTFILES_DIR}…"
# Without --no-folding stow makes ~/.config one symlink into this repo, so every
# app writing there writes into a public working tree. Conflicts must be loud:
# there is no `set -e`, and macOS ships a ~/.zshrc that stow won't overwrite.
if stow_out=$(stow --no-folding --restow . --target="$HOME" --dir="$DOTFILES_DIR" 2>&1); then
  log_ok "Dotfiles" "linked"
else
  echo "$stow_out" >&2
  log_fail "Dotfiles" "stow conflict — move the listed files aside and re-run"
  FAILED+=("Dotfiles (stow)")
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Shell & Prompt (starship, fastfetch, zsh plugins)"; then
section "03  Shell & Prompt"
# ─────────────────────────────────────────────────────────────────────────────
brew_install "zsh"       "Zsh"
brew_install "starship"  "Starship prompt"
brew_install "fastfetch" "Fastfetch"

# KEEP_ZSHRC stops the installer rewriting the .zshrc we just stowed.
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  log_skip "oh-my-zsh" "$HOME/.oh-my-zsh"
else
  log_step "Installing oh-my-zsh…"
  if RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &>/dev/null; then
    log_ok "oh-my-zsh" "installed"
  else
    log_fail "oh-my-zsh" "install failed — .zshrc will error until this is fixed"
    FAILED+=("oh-my-zsh")
  fi
fi

# .zshrc loads these as oh-my-zsh custom plugins; the brew formulae install
# elsewhere and go unused.
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
install_zsh_plugin() {
  local name="$1" url="$2" dest="$ZSH_CUSTOM/plugins/$1"
  if [[ -d "$dest" ]]; then
    log_skip "$name" "$dest"
  else
    log_step "Installing ${name}…"
    if git clone --depth=1 "$url" "$dest" --quiet 2>/dev/null; then
      log_ok "$name" "cloned"
    else
      log_fail "$name" "git clone failed"
      FAILED+=("$name")
    fi
  fi
}
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  install_zsh_plugin "zsh-autosuggestions"     "https://github.com/zsh-users/zsh-autosuggestions"
  install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
  install_zsh_plugin "zsh-256color"            "https://github.com/chrissicool/zsh-256color"
fi

log_step "Setting Zsh as default shell…"
ZSH_PATH="$(brew --prefix)/bin/zsh"
if [[ ! -x "$ZSH_PATH" ]]; then
  log_error "Brew zsh not found at $ZSH_PATH — skipping chsh"
elif [[ "$SHELL" == "$ZSH_PATH" ]]; then
  log_skip "Default shell" "$ZSH_PATH"
else
  grep -q "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
  chsh -s "$ZSH_PATH"
  log_ok "Default shell" "$ZSH_PATH"
fi
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Core CLI tools (bat, eza, fzf, zoxide, ripgrep, fd, jq…)"; then
section "04  Core CLI Tools"
# ─────────────────────────────────────────────────────────────────────────────
brew_install "bat"       "bat (cat replacement)"
brew_install "eza"       "eza (ls replacement)"
brew_install "fzf"       "fzf (fuzzy finder)"
brew_install "zoxide"    "zoxide (smart cd)"
brew_install "direnv"    "direnv"
brew_install "ripgrep"   "ripgrep (rg)"
brew_install "fd"        "fd (find replacement)"
brew_install "jq"        "jq"
brew_install "yq"        "yq"
brew_install "wget"      "wget"
brew_install "htop"      "htop"
brew_install "tldr"      "tldr"
brew_install "tmux"      "tmux"
brew_install "gum"       "gum (Charm scripts)"
brew_install "hyperfine" "hyperfine (benchmarking)"
brew_install "vim"       "vim"
brew_install "watch"     "watch"

log_step "Initialising fzf shell integration…"
"$(brew --prefix)/opt/fzf/install" --all --no-update-rc 2>/dev/null || true
log_ok "fzf" "shell integration ready"
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Git & security (git, lazygit, delta, gh, tig, gitleaks, pre-commit, trivy)"; then
section "05  Git & Security"
# ─────────────────────────────────────────────────────────────────────────────
brew_install "git"        "Git"
brew_install "git-lfs"    "Git LFS"
brew_install "lazygit"    "lazygit"
brew_install "git-delta"  "delta (diff pager)"
brew_install "gh"         "GitHub CLI"
brew_install "tig"        "tig (git TUI)"
brew_install "gitleaks"   "gitleaks (secret scanner)"
brew_install "pre-commit" "pre-commit"
brew_install "trivy"      "trivy (vulnerability scanner)"

if command -v git-lfs &>/dev/null; then
  log_step "Initialising Git LFS…"
  git lfs install --quiet
  log_ok "Git LFS" "initialised"
fi

# core.hooksPath points here; a non-executable hook fails every commit.
GIT_HOOK="$HOME/.config/git/hooks/pre-commit"
if [[ -e "$GIT_HOOK" ]]; then
  chmod +x "$GIT_HOOK" 2>/dev/null || true
  log_ok "git hooks" "gitleaks pre-commit active"
else
  log_error "Expected hook at $GIT_HOOK — is the repo stowed?"
fi
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Neovim + NvChad (neovim, lua, luarocks, cmake, gcc)"; then
section "06  Neovim"
# ─────────────────────────────────────────────────────────────────────────────
brew_install "neovim"    "Neovim"
brew_install "lua"       "Lua"
brew_install "luarocks"  "LuaRocks"
brew_install "make"      "make"
brew_install "cmake"     "cmake"
brew_install "gcc"       "gcc"

log_step "Installing NvChad starter…"
if [ -d "$HOME/.config/nvim/.git" ]; then
  log_skip "NvChad" "already installed at ~/.config/nvim"
else
  rm -rf "$HOME/.config/nvim"
  if git clone https://github.com/NvChad/starter "$HOME/.config/nvim" --quiet; then
    log_ok "NvChad" "cloned — run nvim to finish plugin setup"
  else
    log_fail "NvChad" "git clone failed"
    FAILED+=("NvChad")
  fi
fi
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Node.js ecosystem (node, pnpm)"; then
section "07  Node.js"
# ─────────────────────────────────────────────────────────────────────────────
brew_install "node" "Node.js"
if command -v pnpm &>/dev/null; then
  log_skip "pnpm" "$(pnpm --version)"
else
  log_step "Installing pnpm…"
  npm install -g pnpm --quiet
  log_ok "pnpm" "$(pnpm --version)"
fi
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Python — uv (Astral)"; then
section "08  Python"
# ─────────────────────────────────────────────────────────────────────────────
if command -v uv &>/dev/null; then
  log_skip "uv" "$(uv --version)"
else
  log_step "Installing uv…"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  log_ok "uv" "$(uv --version 2>/dev/null || echo "✓")"
fi
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Go (go, goreleaser)"; then
section "09  Go"
# ─────────────────────────────────────────────────────────────────────────────
brew_install "go"         "Go"
brew_install "goreleaser" "GoReleaser"
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Cloud & DevOps (kubectl, helm, k9s, lazydocker)"; then
section "10  Cloud & DevOps"
# ─────────────────────────────────────────────────────────────────────────────
brew_install "kubectl"    "kubectl"
brew_install "helm"       "Helm"
brew_install "k9s"        "k9s (K8s TUI)"
brew_install "lazydocker" "lazydocker"
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Mac apps (OrbStack, AeroSpace, Raycast, VS Code, TablePlus, Insomnia…)"; then
section "11  Mac Applications"
# ─────────────────────────────────────────────────────────────────────────────
brew_tap "nikitabobko/tap"           # aerospace
brew_tap "theboredteam/boring-notch" # boring-notch
brew_tap "mediosz/tap"               # swipeaerospace

brew_cask_install "orbstack"                        "OrbStack (Docker runtime)"
brew_cask_install "nikitabobko/tap/aerospace"       "AeroSpace (tiling WM)"
brew_cask_install "mediosz/tap/swipeaerospace"      "SwipeAeroSpace"
brew_cask_install "theboredteam/boring-notch/boring-notch" "boringNotch"
brew_cask_install "raycast"                         "Raycast"
brew_cask_install "visual-studio-code"              "VS Code"
brew_cask_install "tableplus"                       "TablePlus"
brew_cask_install "insomnia"                        "Insomnia"
brew_cask_install "hiddenbar"                       "Hidden Bar (menu bar)"
brew_cask_install "stats"                           "Stats (menu bar monitor)"
brew_cask_install "monitorcontrol"                  "MonitorControl"
brew_cask_install "grandperspective"                "GrandPerspective (disk usage)"
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Nerd Fonts (JetBrainsMono, FiraCode)"; then
section "12  Fonts"
# ─────────────────────────────────────────────────────────────────────────────
# Nerd Fonts live in homebrew/cask since 2024 — homebrew/cask-fonts is gone.
brew_cask_install "font-jetbrains-mono-nerd-font" "JetBrainsMono Nerd Font"
brew_cask_install "font-fira-code-nerd-font"      "FiraCode Nerd Font"
fi

# ─────────────────────────────────────────────────────────────────────────────
if [[ ${#FAILED[@]} -gt 0 ]]; then
  section "⚠ Failed installs"
  echo ""
  for pkg in "${FAILED[@]}"; do
    echo -e "  ${RED}✗${RESET} $pkg"
  done
  echo ""
  echo -e "  ${DIM}Re-run the script or install manually with: brew install <pkg>${RESET}"
fi

section "Done — next steps"
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Manual steps remaining:${RESET}"
echo ""
echo -e "  ${YELLOW}1.${RESET}  Create ${CYAN}~/.gitconfig.local${RESET} — email and signing identity for this machine (see README)"
echo -e "  ${YELLOW}2.${RESET}  Create ${CYAN}~/.config/shell/private.sh${RESET}  — private aliases, SSH shortcuts"
echo -e "  ${YELLOW}3.${RESET}  Create ${CYAN}~/.config/shell/vibe.sh${RESET}     — API keys, tooling env vars"
echo -e "  ${YELLOW}4.${RESET}  Work machines only — recreate the internal registry configs:"
echo -e "       ${DIM}~/.config/uv/uv.toml, ~/.config/pip/pip.conf, ~/.config/pnpm/rc${RESET}"
echo -e "  ${YELLOW}5.${RESET}  Set up ${CYAN}~/.ssh/id_ed25519${RESET} and add to GitHub"
echo -e "       ${DIM}ssh-keygen -t ed25519 -C \"your@email.com\"${RESET}"
echo -e "       ${DIM}gh ssh-key add ~/.ssh/id_ed25519.pub --title \"$(hostname)\"${RESET}"
echo -e "  ${YELLOW}6.${RESET}  Sign in: ${CYAN}gh auth login${RESET}"
echo -e "  ${YELLOW}7.${RESET}  Restart your terminal"
echo ""
echo -e "${BOLD}${GREEN}  All done. Welcome to your new Mac.${RESET}"
echo ""

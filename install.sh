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
  local label="$1"
  if $AUTO_YES; then return 0; fi
  printf "\n  ${BOLD}Install %s?${RESET} [Y/n] " "$label"
  read -r ans
  [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

brew_install() {
  local pkg="$1" label="${2:-$1}"
  if brew list --formula "$pkg" &>/dev/null; then
    log_skip "$label" "$(brew info --json "$pkg" 2>/dev/null | jq -r '.[0].versions.stable' 2>/dev/null || echo "installed")"
  else
    log_step "Installing ${label}…"
    if brew install "$pkg" --quiet 2>/dev/null; then
      log_ok "$label" "$(brew info --json "$pkg" 2>/dev/null | jq -r '.[0].versions.stable' 2>/dev/null || echo "✓")"
    else
      log_fail "$label" "brew install $pkg failed — skipping"
      FAILED+=("$label")
    fi
  fi
}

brew_cask_install() {
  local pkg="$1" label="${2:-$1}"
  if brew list --cask "$pkg" &>/dev/null; then
    log_skip "$label" "$(brew info --cask "$pkg" 2>/dev/null | head -1 | awk '{print $NF}' || echo "installed")"
  else
    log_step "Installing ${label} (cask)…"
    if brew install --cask "$pkg" --quiet 2>/dev/null; then
      log_ok "$label" "installed"
    else
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
stow . --target="$HOME" --dir="$DOTFILES_DIR" --restow
log_ok "Dotfiles" "linked"

# ─────────────────────────────────────────────────────────────────────────────
if ask "Shell & Prompt (starship, fastfetch, zsh plugins)"; then
section "03  Shell & Prompt"
# ─────────────────────────────────────────────────────────────────────────────
brew_install "zsh"                     "Zsh"
brew_install "starship"                "Starship prompt"
brew_install "fastfetch"               "Fastfetch"
brew_install "zsh-autosuggestions"     "zsh-autosuggestions"
brew_install "zsh-syntax-highlighting" "zsh-syntax-highlighting"

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

log_step "Initialising fzf shell integration…"
"$(brew --prefix)/opt/fzf/install" --all --no-update-rc 2>/dev/null || true
log_ok "fzf" "shell integration ready"
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Git tools (git, lazygit, delta, gh, tig, git-lfs)"; then
section "05  Git"
# ─────────────────────────────────────────────────────────────────────────────
brew_install "git"       "Git"
brew_install "git-lfs"   "Git LFS"
brew_install "lazygit"   "lazygit"
brew_install "git-delta" "delta (diff pager)"
brew_install "gh"        "GitHub CLI"
brew_install "tig"       "tig (git TUI)"

log_step "Configuring global git settings…"
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global init.defaultBranch "main"
log_ok "Git config" "delta pager, defaultBranch=main"
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
if ask "Mac apps (Docker, AeroSpace, Raycast, VS Code, TablePlus, Insomnia, Shottr)"; then
section "11  Mac Applications"
# ─────────────────────────────────────────────────────────────────────────────
brew_cask_install "docker"             "Docker Desktop"
brew_cask_install "aerospace"          "AeroSpace (tiling WM)"
brew_cask_install "raycast"            "Raycast"
brew_cask_install "visual-studio-code" "VS Code"
brew_cask_install "tableplus"          "TablePlus"
brew_cask_install "insomnia"           "Insomnia"
brew_cask_install "shottr"             "Shottr (screenshots)"
fi

# ─────────────────────────────────────────────────────────────────────────────
if ask "Nerd Fonts (JetBrainsMono, FiraCode)"; then
section "12  Fonts"
# ─────────────────────────────────────────────────────────────────────────────
brew tap homebrew/cask-fonts 2>/dev/null || true
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
echo -e "  ${YELLOW}3.${RESET}  Create ${CYAN}~/.config/shell/vibe.sh${RESET}     — vibe coding / AI env vars"
echo -e "  ${YELLOW}4.${RESET}  Set up ${CYAN}~/.ssh/id_ed25519${RESET} and add to GitHub"
echo -e "       ${DIM}ssh-keygen -t ed25519 -C \"your@email.com\"${RESET}"
echo -e "       ${DIM}gh ssh-key add ~/.ssh/id_ed25519.pub --title \"$(hostname)\"${RESET}"
echo -e "  ${YELLOW}5.${RESET}  Sign in: ${CYAN}gh auth login${RESET}"
echo -e "  ${YELLOW}6.${RESET}  Restart your terminal"
echo ""
echo -e "${BOLD}${GREEN}  All done. Welcome to your new Mac.${RESET}"
echo ""

#!/usr/bin/env bash
# setup-claude-devc.sh
# Bootstrap a fresh Ubuntu machine for Claude Code + Trail of Bits devcontainer
# Usage: bash setup-claude-devc.sh
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[•]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
die()     { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Don't run as root. Run as your normal user (sudo will be used where needed)."
CURRENT_USER="$(whoami)"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Claude Code + devc bootstrap for Ubuntu      ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Base deps + Docker + Node — all from standard Ubuntu repos
info "Installing packages via apt..."
sudo apt-get update -qq
sudo apt-get install -y \
    git \
    jq \
    unzip \
    docker.io \
    nodejs \
    npm
success "Packages installed"

# 2. Docker group
sudo systemctl enable --now docker
if groups "$CURRENT_USER" | grep -q '\bdocker\b'; then
    success "User '$CURRENT_USER' already in docker group"
else
    info "Adding '$CURRENT_USER' to docker group..."
    sudo usermod -aG docker "$CURRENT_USER"
fi

# 3. @devcontainers/cli  (no apt package — npm only)
if command -v devcontainer &>/dev/null; then
    success "@devcontainers/cli already installed"
else
    info "Installing @devcontainers/cli via npm..."
    sudo npm install -g @devcontainers/cli
    success "@devcontainers/cli installed"
fi

# 4. Trail of Bits devcontainer
DEVC_DIR="$HOME/.claude-devcontainer"
if [[ -d "$DEVC_DIR/.git" ]]; then
    info "Already cloned, pulling latest..."
    git -C "$DEVC_DIR" pull --ff-only
else
    info "Cloning trailofbits/claude-code-devcontainer..."
    git clone https://github.com/trailofbits/claude-code-devcontainer "$DEVC_DIR"
fi
success "devcontainer ready at $DEVC_DIR"

# 5. devc CLI
export PATH="$HOME/.local/bin:$PATH"
if command -v devc &>/dev/null; then
    success "devc already installed"
else
    info "Installing devc to ~/.local/bin..."
    bash "$DEVC_DIR/install.sh" self-install
    success "devc installed"
fi

if ! grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    info "Added ~/.local/bin to PATH in ~/.bashrc"
fi

# 6. Done
echo ""
if docker info &>/dev/null 2>&1; then
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  All done!                                        ${NC}"
    echo -e "${GREEN}                                                  ${NC}"
    echo -e "${GREEN}    cd your-project                               ${NC}"
    echo -e "${GREEN}    devc .                                        ${NC}"
    echo -e "${GREEN}                                                  ${NC}"
    echo -e "${GREEN}  First run will prompt you to log in via browser.${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
else
    echo -e "${YELLOW}  Docker group change needs a new shell. Run:${NC}"
    echo ""
    echo -e "    ${CYAN}newgrp docker${NC}"
    echo ""
    echo -e "  Then: ${CYAN}cd your-project && devc .${NC}"
fi
echo ""

#!/usr/bin/env bash
# Refresh Catppuccin atuin theme from upstream (optional; dotfiles vendors one file).
set -euo pipefail

repo="https://raw.githubusercontent.com/catppuccin/atuin/main"
flavor="${ATUIN_CATPPUCCIN_FLAVOR:-mocha}"
theme="${ATUIN_CATPPUCCIN_THEME:-catppuccin-mocha-teal}"
dest="${DOTFILES_ATUIN_THEMES:-$HOME/dotfiles/config/atuin/themes}"

mkdir -p "$dest"
url="${repo}/themes/${flavor}/${theme}.toml"
echo "atuin-catppuccin-theme: ${url} -> ${dest}/${theme}.toml"
curl -fsSL "$url" -o "${dest}/${theme}.toml"

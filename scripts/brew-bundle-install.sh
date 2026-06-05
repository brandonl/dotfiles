#!/usr/bin/env bash
# Install Brewfile deps and upgrade anything outdated (no version pinning).
set -euo pipefail

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

brew bundle install --upgrade --file "$dotfiles/Brewfile"

if [[ -f "$dotfiles/Brewfile.local" ]]; then
  brew bundle install --upgrade --file "$dotfiles/Brewfile.local"
fi

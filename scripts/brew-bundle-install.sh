#!/usr/bin/env bash
# Install Brewfile deps and upgrade anything outdated (no version pinning).
set -euo pipefail

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Homebrew uses this name for private GitHub release metadata. Reuse the
# caller's GitHub CLI token without persisting a duplicate secret.
if [[ -z "${HOMEBREW_GITHUB_API_TOKEN:-}" && -n "${GH_TOKEN:-}" ]]; then
  export HOMEBREW_GITHUB_API_TOKEN="$GH_TOKEN"
fi

# Homebrew >=6 refuses to load formulae/casks/commands from non-official taps
# unless they are trusted. Trust every tap declared in our Brewfiles first.
trust_taps() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  while IFS= read -r tap; do
    case "$tap" in
      homebrew/*) ;; # official taps are always trusted
      *) brew trust --tap "$tap" ;;
    esac
  done < <(sed -nE "s/^[[:space:]]*tap[[:space:]]+['\"]([^'\"]+)['\"].*/\\1/p" "$file")
}

trust_taps "$dotfiles/Brewfile"
trust_taps "$dotfiles/Brewfile.local"

brew bundle install --upgrade --file "$dotfiles/Brewfile"

if [[ -f "$dotfiles/Brewfile.local" ]]; then
  brew bundle install --upgrade --file "$dotfiles/Brewfile.local"
fi

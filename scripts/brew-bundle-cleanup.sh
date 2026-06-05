#!/usr/bin/env bash

set -euo pipefail

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
brewfile="$dotfiles/Brewfile"
local="$dotfiles/Brewfile.local"

if [[ -f "$local" ]]; then
  combined="$(mktemp)"
  trap 'rm -f "$combined"' EXIT
  cat "$brewfile" "$local" > "$combined"
  brewfile="$combined"
fi

exec brew bundle cleanup --file "$brewfile" "$@"

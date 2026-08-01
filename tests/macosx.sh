#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/scripts/macosx.sh"

if rg -n 'restart-apps\.sh|killall' "$script"; then
  echo "macosx.sh must not restart GUI processes during installation" >&2
  exit 1
fi

rg -F 'macOS settings applied.' "$script" >/dev/null

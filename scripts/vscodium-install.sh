#!/usr/bin/env bash

set -euo pipefail

if ! command -v codium >/dev/null 2>&1; then
  echo "[!] VSCodium unavailable; skipping extensions"
  exit 0
fi

while IFS= read -r extension; do
  [[ -z "$extension" || "$extension" == \#* ]] && continue
  codium --install-extension "$extension"
done < "$(dirname "$0")/../vscodium/extensions.txt"

#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for file in settings.json keymap.json; do
  path="config/zed/$file"
  [[ -f "$repo_root/$path" ]]
  if git -C "$repo_root" check-ignore -q "$path"; then
    echo "$path is ignored and will not sync to another machine" >&2
    exit 1
  fi
done

for extension in catppuccin catppuccin-icons one-dark-pro snazzy tokyo-night; do
  rg -F "\"$extension\": true" "$repo_root/config/zed/settings.json" >/dev/null
done

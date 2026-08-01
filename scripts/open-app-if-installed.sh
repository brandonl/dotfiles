#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" != "1" ]]; then
  echo "usage: $0 /path/to/Application.app" >&2
  exit 2
fi

app_path="$1"
if [[ ! -d "$app_path" ]]; then
  echo "Application unavailable; skipped launch: $app_path"
  exit 0
fi

"${OPEN_APP_COMMAND:-open}" -gj "$app_path"

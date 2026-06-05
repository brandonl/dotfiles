#!/usr/bin/env bash
set -euo pipefail

if ! command -v mise >/dev/null 2>&1; then
  echo "mise-install: mise not on PATH, skipping" >&2
  exit 0
fi

echo "mise-install: installing runtimes from config"
mise install

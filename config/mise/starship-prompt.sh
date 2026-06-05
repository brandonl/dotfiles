#!/usr/bin/env bash
# Print mise tools activated by project files (not global ~/.config/mise/config.toml).
set -euo pipefail

global_config="${HOME}/.config/mise/config.toml"
[[ -f "$global_config" ]] || exit 0
global_path="$(realpath "$global_config")"

mise ls --current --json 2>/dev/null | jq -r --arg g "$global_config" --arg gr "$global_path" '
  [
    to_entries[]
    | .value[0] as $e
    | select($e.source.path != null and $e.source.path != $g and $e.source.path != $gr)
    | "\(.key)@\($e.version)"
  ] | join(" ")
'

#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fake_home="$test_root/home"
fake_config="$fake_home/.config"
mkdir -p "$fake_config/mole"

HOME="$fake_home" XDG_CONFIG_HOME="$fake_config" \
  "$repo_root/scripts/doctor.sh" --config-hygiene >/dev/null

mkdir "$fake_config/unexpected"
ln -s "$test_root/missing" "$fake_config/broken"

if HOME="$fake_home" XDG_CONFIG_HOME="$fake_config" \
  "$repo_root/scripts/doctor.sh" --config-hygiene \
  >"$test_root/output" 2>&1; then
  echo "stale config unexpectedly accepted" >&2
  exit 1
fi

rg -F "broken symlink: $fake_config/broken" "$test_root/output" >/dev/null
rg -F "unclassified config: $fake_config/unexpected" "$test_root/output" >/dev/null

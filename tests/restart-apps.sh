#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

cat >"$test_root/killall" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" >>"$KILLALL_LOG"
exit 1
EOF
chmod +x "$test_root/killall"

KILLALL_LOG="$test_root/killall.log" \
PATH="$test_root:$PATH" \
  "$repo_root/scripts/restart-apps.sh" Dock Finder

diff -u <(printf 'Dock\nFinder\n') "$test_root/killall.log"

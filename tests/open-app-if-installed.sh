#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fake_open="$test_root/open"
cat >"$fake_open" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"$OPEN_APP_LOG"
EOF
chmod +x "$fake_open"

OPEN_APP_COMMAND="$fake_open" \
OPEN_APP_LOG="$test_root/open.log" \
  "$repo_root/scripts/open-app-if-installed.sh" "$test_root/missing.app"
[[ ! -e "$test_root/open.log" ]]

mkdir "$test_root/Clocker.app"
OPEN_APP_COMMAND="$fake_open" \
OPEN_APP_LOG="$test_root/open.log" \
  "$repo_root/scripts/open-app-if-installed.sh" "$test_root/Clocker.app"

diff -u <(printf '%s\n' -gj "$test_root/Clocker.app") "$test_root/open.log"

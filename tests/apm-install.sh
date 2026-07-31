#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fake_bin="$test_root/bin"
mkdir -p "$fake_bin"

cat >"$fake_bin/apm" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat >"$fake_bin/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$1 $2 $3" == "mcp list --json" ]]; then
  [[ "${CODEX_MCP_LIST_RESULT:-valid}" == "valid" ]] || exit 1
  printf '[]\n'
  exit 0
fi

printf '%q ' "$@" >>"$CODEX_MCP_LOG"
printf '\n' >>"$CODEX_MCP_LOG"
EOF

chmod +x "$fake_bin/apm" "$fake_bin/codex"

while IFS= read -r manifest; do
  if yq '.targets[]' "$manifest" | rg -Fx 'codex' >/dev/null; then
    echo "APM must not target Codex directly: $manifest" >&2
    exit 1
  fi
done < <(find "$repo_root/apm" -name apm.yml -type f | sort)

export PATH="$fake_bin:$PATH"
export HOME="$test_root/home"
export CODEX_MCP_LOG="$test_root/codex-mcp.log"

if CODEX_MCP_LIST_RESULT=invalid "$repo_root/scripts/apm-install.sh" >/dev/null 2>&1; then
  echo "invalid Codex config unexpectedly accepted" >&2
  exit 1
fi

[[ ! -e "$CODEX_MCP_LOG" ]]

CODEX_MCP_LIST_RESULT=valid "$repo_root/scripts/apm-install.sh" >/dev/null
rg -Fx 'mcp add context7 -- npx -y @upstash/context7-mcp ' "$CODEX_MCP_LOG" >/dev/null

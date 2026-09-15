#!/usr/bin/env bash

set -euo pipefail

source_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

repo_root="$test_root/repo"
fake_bin="$test_root/bin"
mkdir -p "$fake_bin" "$repo_root/scripts" "$repo_root/apm/global"
cp "$source_root/scripts/apm-install.sh" "$repo_root/scripts/apm-install.sh"
cp "$source_root/apm/global/apm.yml" "$repo_root/apm/global/apm.yml"
cp "$source_root/apm/global/apm.lock.yaml" "$repo_root/apm/global/apm.lock.yaml"
cp -R "$source_root/apm/global/packages" "$repo_root/apm/global/packages"

cat >"$fake_bin/brew" <<EOF
#!/usr/bin/env bash
[[ "\$1" == "--prefix" ]]
printf '%s\n' "$test_root"
EOF

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

chmod +x "$fake_bin/apm" "$fake_bin/brew" "$fake_bin/codex"

yq '.targets[]' "$repo_root/apm/global/apm.yml" | rg -Fx 'codex' >/dev/null

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
cmp "$repo_root/apm/global/apm.yml" "$HOME/.apm/apm.yml"
cmp \
  "$repo_root/apm/global/packages/personal-instructions/.apm/instructions/personal.instructions.md" \
  "$HOME/.apm/packages/personal-instructions/.apm/instructions/personal.instructions.md"
cmp \
  "$repo_root/apm/global/packages/personal-instructions/.apm/instructions/personal.instructions.md" \
  "$HOME/.apm/apm_modules/_local/personal-instructions/.apm/instructions/personal.instructions.md"

cat >"$repo_root/apm/global/apm.local.yml" <<'EOF'
dependencies:
  apm:
    - git: example/work-only
      targets: [agent-skills]
EOF
cp "$repo_root/apm/global/apm.lock.yaml" "$repo_root/apm/global/apm.local.lock.yaml"

CODEX_MCP_LIST_RESULT=valid "$repo_root/scripts/apm-install.sh" >/dev/null
yq eval-all 'select(fileIndex == 0) *+ select(fileIndex == 1)' \
  "$repo_root/apm/global/apm.yml" \
  "$repo_root/apm/global/apm.local.yml" >"$test_root/expected-apm.yml"
cmp "$test_root/expected-apm.yml" "$HOME/.apm/apm.yml"

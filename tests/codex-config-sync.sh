#!/usr/bin/env bash

set -euo pipefail

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/home/.codex" "$test_root/bin"
cat >"$test_root/home/.codex/config.toml" <<'EOF'
# Keep this local comment.
model = "old-model"

[projects."/example/work-project"]
trust_level = "trusted"

[mcp_servers.private]
command = "/example/local-server"
EOF
cat >"$test_root/home/.codex/hooks.json" <<'EOF'
{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"other hook"}]}]}}
EOF
cat >"$test_root/bin/rtk" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$*" == "init -g --codex" ]]
printf '%s\n' called >>"$HOME/rtk-calls"
jq '.hooks.PreToolUse += [{"matcher":"Bash","hooks":[{"type":"command","command":"rtk hook codex"}]}]' \
  "$HOME/.codex/hooks.json" >"$HOME/.codex/hooks.new"
mv "$HOME/.codex/hooks.new" "$HOME/.codex/hooks.json"
EOF
chmod +x "$test_root/bin/rtk"

HOME="$test_root/home" PATH="$test_root/bin:$PATH" \
	uv run --script "$dotfiles/scripts/codex-config-sync.py"
config="$test_root/home/.codex/config.toml"
rg -F '# Keep this local comment.' "$config" >/dev/null
yq -p toml -o json '.' "$config" | jq -e '
  .model == "gpt-6-sol" and
  .features.hooks == true and
  .projects["/example/work-project"].trust_level == "trusted" and
  .mcp_servers.private.command == "/example/local-server"
' >/dev/null
jq -e '[.hooks.PreToolUse[].hooks[] | select(.command == "rtk hook codex")] | length == 1' \
	"$test_root/home/.codex/hooks.json" >/dev/null
[[ "$(wc -l <"$test_root/home/rtk-calls")" -eq 1 ]]

first_hash="$(shasum -a 256 "$config")"
HOME="$test_root/home" PATH="$test_root/bin:$PATH" \
	uv run --script "$dotfiles/scripts/codex-config-sync.py"
[[ "$(shasum -a 256 "$config")" == "$first_hash" ]]
[[ "$(wc -l <"$test_root/home/rtk-calls")" -eq 1 ]]

cp "$dotfiles/config/codex/preferences.toml" "$config"
CODEX_TEST_CONFIG="$config" python3 - <<'PY'
import os
from pathlib import Path

path = Path(os.environ["CODEX_TEST_CONFIG"])
content = path.read_text().replace('model = "gpt-6-sol"', "model = 'gpt-6-sol'", 1)
path.write_text("# Keep exact formatting when values already match.\n" + content)
PY
format_hash="$(shasum -a 256 "$config")"
HOME="$test_root/home" PATH="$test_root/bin:$PATH" \
	uv run --script "$dotfiles/scripts/codex-config-sync.py"
[[ "$(shasum -a 256 "$config")" == "$format_hash" ]]

shared="$dotfiles/config/codex/preferences.toml"
yq -p toml -o json '.' "$shared" | jq -e '
  (keys - ["model", "model_reasoning_effort", "personality", "service_tier", "desktop", "features", "memories", "tui"]) == []
' >/dev/null
if rg -n -i 'rewardstyle|engx|ktl|/Users/|api[_-]?key|password|secret' "$shared"; then
	echo "Work-specific or machine-specific Codex preferences found" >&2
	exit 1
fi

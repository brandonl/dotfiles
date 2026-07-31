#!/usr/bin/env bash
set -euo pipefail

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
update=0

sync_codex_context7() {
  if ! command -v codex >/dev/null 2>&1; then
    echo "[i] Codex CLI not installed; skipped Context7 MCP setup"
    return
  fi

  local servers
  if ! servers="$(codex mcp list --json)"; then
    echo "[x] Codex MCP config is invalid; refusing to modify ~/.codex/config.toml" >&2
    return 1
  fi

  if jq -e '
    .[] | select(
      .name == "context7" and
      .transport.type == "stdio" and
      .transport.command == "npx" and
      .transport.args == ["-y", "@upstash/context7-mcp"]
    )
  ' <<<"$servers" >/dev/null; then
    return
  fi

  if jq -e '.[] | select(.name == "context7")' <<<"$servers" >/dev/null; then
    echo "[x] Existing Codex MCP 'context7' differs from dotfiles configuration; refusing to overwrite it" >&2
    return 1
  fi

  codex mcp add context7 -- npx -y @upstash/context7-mcp
}

if [[ "${1:-}" == "--update" ]]; then
  update=1
  shift
fi

if (( $# )); then
  echo "usage: $0 [--update]" >&2
  exit 2
fi

if ! command -v apm >/dev/null 2>&1; then
  curl -fsSL https://aka.ms/apm-unix | sh
  hash -r
fi

mkdir -p "$HOME/.apm"
install -m 600 "$dotfiles/apm/global/apm.yml" "$HOME/.apm/apm.yml"
install -m 600 "$dotfiles/apm/global/apm.lock.yaml" "$HOME/.apm/apm.lock.yaml"

if (( update )); then
  apm lock --global --update
  install -m 600 "$HOME/.apm/apm.lock.yaml" "$dotfiles/apm/global/apm.lock.yaml"
  apm install --global --frozen
else
  apm install --global --frozen
fi

apm compile --global
sync_codex_context7

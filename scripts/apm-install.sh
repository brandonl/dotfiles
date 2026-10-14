#!/usr/bin/env bash
set -euo pipefail

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
public_manifest="$dotfiles/apm/global/apm.yml"
public_lock="$dotfiles/apm/global/apm.lock.yaml"
local_manifest="$dotfiles/apm/global/apm.local.yml"
local_lock="$dotfiles/apm/global/apm.local.lock.yaml"
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

sync_claude_skill_overrides() {
  local overrides="$dotfiles/apm/global/claude-skill-overrides.json"
  local settings="$HOME/.claude/settings.json"
  local merged

  mkdir -p "$HOME/.claude"
  if [[ -L "$settings" ]]; then
    settings="$(realpath "$settings")"
  fi
  if [[ -f "$settings" ]] && jq -e -s \
    '.[0] as $current | .[1] as $override | ($current * $override) == $current' \
    "$settings" "$overrides" >/dev/null; then
    return
  fi

  merged="$(mktemp "$HOME/.claude/.settings.json.XXXXXX")"
  if [[ -f "$settings" ]]; then
    jq -s '.[0] * .[1]' "$settings" "$overrides" >"$merged"
  else
    jq . "$overrides" >"$merged"
  fi
  chmod 600 "$merged"
  mv "$merged" "$settings"
}

if [[ "${1:-}" == "--update" ]]; then
  update=1
  shift
fi

if (($#)); then
  echo "usage: $0 [--update]" >&2
  exit 2
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "[x] Homebrew is required to install APM" >&2
  exit 1
fi

apm_bin="$(brew --prefix)/bin/apm"
if [[ ! -x "$apm_bin" ]]; then
  echo "[x] Homebrew APM is missing; run: brew bundle --file $dotfiles/Brewfile" >&2
  exit 1
fi

mkdir -p "$HOME/.apm"
if [[ -f "$local_manifest" ]]; then
  yq eval-all 'select(fileIndex == 0) *+ select(fileIndex == 1)' \
    "$public_manifest" "$local_manifest" >"$HOME/.apm/apm.yml"
  chmod 600 "$HOME/.apm/apm.yml"
  lock="$local_lock"
else
  install -m 600 "$public_manifest" "$HOME/.apm/apm.yml"
  lock="$public_lock"
fi

mkdir -p "$HOME/.apm/packages"
rsync -a --delete "$dotfiles/apm/global/packages/" "$HOME/.apm/packages/"

if ((update)) || [[ ! -f "$lock" ]]; then
  lock_args=(--global)
  ((update)) && lock_args+=(--update)
  "$apm_bin" lock "${lock_args[@]}"
  install -m 600 "$HOME/.apm/apm.lock.yaml" "$lock"
else
  install -m 600 "$lock" "$HOME/.apm/apm.lock.yaml"
fi

"$apm_bin" install --global --frozen

# Reapply Codex metadata after APM replaces the upstream skill directories.
for metadata in "$dotfiles"/apm/global/overrides/*/agents/openai.yaml; do
  [[ -f "$metadata" ]] || continue
  skill="$(basename "$(dirname "$(dirname "$metadata")")")"
  for skills_dir in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
    [[ -f "$skills_dir/$skill/SKILL.md" ]] || continue
    destination="$skills_dir/$skill/agents/openai.yaml"
    mkdir -p "$(dirname "$destination")"
    if [[ -f "$destination" ]]; then
      merged="$(yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
        "$destination" "$metadata")"
      printf '%s\n' "$merged" >"$destination"
    else
      install -m 644 "$metadata" "$destination"
    fi
  done
done

# APM 0.30 records global local dependencies but does not retain them under
# apm_modules, where global compilation reads instructions from.
mkdir -p "$HOME/.apm/apm_modules/_local"
rsync -a --delete "$dotfiles/apm/global/packages/" "$HOME/.apm/apm_modules/_local/"

"$apm_bin" compile --global
sync_claude_skill_overrides
sync_codex_context7

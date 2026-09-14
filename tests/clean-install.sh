#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fake_home="$test_root/home"
link_config="$test_root/links.yaml"
mkdir -p "$fake_home"

yq '[.[] | select(has("defaults") or has("link"))] |
  (.[] | select(has("link")) | .link) |=
    del(."~/.zsh/omz/custom/plugins/")' \
  "$repo_root/install.conf.yaml" >"$link_config"

HOME="$fake_home" "$repo_root/dotbot/bin/dotbot" \
  -d "$repo_root" \
  -c "$link_config"

expected_links=(
  ".zshrc"
  ".config/mise/config.toml"
  ".config/zed/settings.json"
  ".vscode-oss/argv.json"
  "Library/Application Support/VSCodium/User/settings.json"
  "Library/Application Support/VSCodium/User/keybindings.json"
)

for link in "${expected_links[@]}"; do
  [[ -L "$fake_home/$link" ]]
  [[ -e "$fake_home/$link" ]]
done

while IFS= read -r link; do
  [[ -e "$link" ]]
done < <(find "$fake_home" -type l)

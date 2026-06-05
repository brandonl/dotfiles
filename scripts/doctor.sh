#!/usr/bin/env bash
set -u -o pipefail

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

ok() {
  printf 'ok   %s\n' "$1"
}

fail() {
  printf 'fail %s\n' "$1" >&2
  failures=$((failures + 1))
}

check() {
  local label="$1"
  shift

  if "$@"; then
    ok "$label"
  else
    fail "$label"
  fi
}

have() {
  command -v "$1" >/dev/null 2>&1
}

brew_bundle_check() {
  have brew || return 1
  local status=0

  printf 'checking Brewfile\n'
  brew bundle check --verbose --file "$dotfiles/Brewfile" || status=1

  if [[ -f "$dotfiles/Brewfile.local" ]]; then
    printf 'checking Brewfile.local\n'
    brew bundle check --verbose --file "$dotfiles/Brewfile.local" || status=1
  fi

  return "$status"
}

submodules_clean() {
  git -C "$dotfiles" submodule status --recursive |
    awk 'BEGIN { bad = 0 } /^[+-]/ { bad = 1 } END { exit bad }'
}

dotfile_links() {
  local link target resolved
  local -a links=(
    "$HOME/.zshrc:$dotfiles/zshrc"
    "$HOME/.zlogin:$dotfiles/zlogin"
    "$HOME/.gitconfig:$dotfiles/git/gitconfig"
    "$HOME/.githelpers:$dotfiles/git/githelpers"
    "$HOME/.gitignore:$dotfiles/git/gitignore"
    "$HOME/.config/starship.toml:$dotfiles/config/starship.toml"
    "$HOME/.config/atuin/config.toml:$dotfiles/config/atuin/config.toml"
    "$HOME/.config/mise/config.toml:$dotfiles/config/mise/config.toml"
    "$HOME/.config/bat/config:$dotfiles/config/bat/config"
  )

  for pair in "${links[@]}"; do
    link="${pair%%:*}"
    target="${pair#*:}"

    if [[ ! -L "$link" ]]; then
      printf 'missing symlink: %s\n' "$link" >&2
      return 1
    fi

    resolved="$(realpath "$link" 2>/dev/null)" || return 1
    if [[ "$resolved" != "$target" ]]; then
      printf 'bad symlink: %s -> %s (wanted %s)\n' "$link" "$resolved" "$target" >&2
      return 1
    fi
  done
}

zsh_syntax() {
  have zsh || return 1

  local file
  for file in "$dotfiles"/zsh/*.zsh "$dotfiles"/zshrc "$dotfiles"/zlogin; do
    zsh -n "$file" || return 1
  done
}

script_syntax() {
  local file
  for file in "$dotfiles"/scripts/*.sh; do
    bash -n "$file" || return 1
  done
}

compaudit_clean() {
  have zsh || return 1

  local output
  output="$(zsh -ic 'autoload -Uz compaudit; compaudit' 2>/dev/null)"
  if [[ -n "$output" ]]; then
    printf '%s\n' "$output" >&2
    return 1
  fi
}

check "brew bundle" brew_bundle_check
check "submodules" submodules_clean
check "dotfile links" dotfile_links
check "zsh syntax" zsh_syntax
check "script syntax" script_syntax
check "mise" have mise
check "atuin" have atuin
check "compaudit" compaudit_clean

if (( failures )); then
  printf '\n%d check(s) failed\n' "$failures" >&2
  exit 1
fi

printf '\nall checks passed\n'

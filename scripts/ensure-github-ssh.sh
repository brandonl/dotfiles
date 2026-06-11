#!/usr/bin/env bash
# Bootstrap GitHub SSH on first install; no-op when auth already works.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

PRIVATE_KEY="$HOME/.ssh/id_ed25519"
PUBLIC_KEY="${PRIVATE_KEY}.pub"

github_ssh_works() {
  local -a ssh_opts=(-o BatchMode=yes -o ConnectTimeout=10)
  local output
  if [[ -f "$PRIVATE_KEY" ]]; then
    ssh_opts+=(-i "$PRIVATE_KEY" -o IdentitiesOnly=yes)
  fi
  output="$(ssh "${ssh_opts[@]}" -T git@github.com 2>&1)" || true
  grep -qi 'successfully authenticated' <<<"$output"
}

# 0 = on GitHub, 1 = not on GitHub, 2 = cannot list keys (missing gh scope, etc.)
key_on_github() {
  local pubkey keys
  pubkey="$(awk '{print $1" "$2}' "$PUBLIC_KEY")"
  keys="$(gh api user/keys --jq '.[].key' 2>/dev/null)" || return 2
  grep -qF "$pubkey" <<<"$keys"
}

ensure_key_loaded() {
  if [[ -z "${SSH_AUTH_SOCK:-}" ]] || ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)"
  fi

  local fingerprint
  fingerprint="$(ssh-keygen -lf "$PUBLIC_KEY" | awk '{print $2}')"
  if ssh-add -l 2>/dev/null | grep -qF "$fingerprint"; then
    return 0
  fi

  ssh-add --apple-use-keychain "$PRIVATE_KEY" 2>/dev/null || ssh-add "$PRIVATE_KEY"
}

if github_ssh_works; then
  echo "GitHub SSH already works"
  exit 0
fi

if ! command -v gh >/dev/null; then
  echo "gh not found; install Brewfile packages first" >&2
  exit 1
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ ! -f "$PRIVATE_KEY" ]]; then
  echo "Generating SSH key at $PRIVATE_KEY"
  ssh-keygen -t ed25519 -C "brandonl@users.noreply.github.com" -f "$PRIVATE_KEY"
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI auth required"
  gh auth login
fi

ensure_key_loaded

if github_ssh_works; then
  echo "GitHub SSH ready"
  exit 0
fi

key_on_github
key_status=$?
if [[ "$key_status" -eq 0 ]]; then
  echo "SSH key is on GitHub but auth still fails; check ~/.ssh/config" >&2
  exit 1
fi
if [[ "$key_status" -eq 2 ]]; then
  echo "Cannot list GitHub SSH keys (gh may need admin:public_key scope)"
fi

echo "Uploading SSH public key to GitHub"
if ! gh ssh-key add "$PUBLIC_KEY" --title "$(hostname -s)"; then
  echo "Auto-upload failed. Try: gh auth refresh -s admin:public_key" >&2
  echo "Or add the key at https://github.com/settings/keys" >&2
  exit 1
fi

if github_ssh_works; then
  echo "GitHub SSH ready"
  exit 0
fi

echo "GitHub SSH setup failed; try: ssh -T git@github.com" >&2
exit 1

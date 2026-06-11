# Use keychain to keep ssh-agent information available in a file
if command -v keychain >/dev/null && [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  keychain --quiet "$HOME/.ssh/id_ed25519"
  [[ -f "$HOME/.keychain/${HOST}-sh" ]] && . "$HOME/.keychain/${HOST}-sh"
fi

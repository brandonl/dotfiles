# Use keychain to keep ssh-agent information available in a file
keychain --quiet "$HOME/.ssh/id_ed25519"
. "$HOME/.keychain/${HOST}-sh"

# Keep zsh path array and PATH string deduped.
typeset -U path PATH

[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -n "$DOTFILES" && -d "$DOTFILES/bin" ]] && path+=("$DOTFILES/bin")
[[ -d "$HOME/bin" ]] && path+=("$HOME/bin")
# Prepend Homebrew so it wins over stale binaries in inherited /usr/local/bin.
[[ -d "/opt/homebrew/bin" ]] && path=("/opt/homebrew/bin" $path)
[[ -d "/opt/homebrew/sbin" ]] && path=("/opt/homebrew/sbin" $path)

[[ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]] && path+=("/Applications/Visual Studio Code.app/Contents/Resources/app/bin")

[[ -n "$GOPATH" && -d "$GOPATH/bin" ]] && path+=("$GOPATH/bin")

export PATH

# Keep zsh path array and PATH string deduped.
typeset -U path PATH

[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/bin" ]] && path+=("$HOME/bin")
[[ -d "/opt/homebrew/bin" ]] && path+=("/opt/homebrew/bin")
[[ -d "/usr/local/bin" ]] && path+=("/usr/local/bin")

[[ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]] && path+=("/Applications/Visual Studio Code.app/Contents/Resources/app/bin")

[[ -n "$GOPATH" && -d "$GOPATH/bin" ]] && path+=("$GOPATH/bin")

export PATH
